"""Manual Wayland regression check in an isolated compositor; no real passwords.

Requires a running Wayland session, Hyprland, Quickshell and ffmpeg. The temporary
copy gets a screenshot-only IPC probe; production files and the desktop are untouched.
"""
from pathlib import Path
import argparse, json, os, shutil, subprocess, tempfile, time
import struct

parser = argparse.ArgumentParser()
parser.add_argument('source', nargs='?', type=Path,
                    default=Path(__file__).resolve().parents[1] / 'home/.config/quickshell/arch-lock')
args = parser.parse_args()
if not os.environ.get('WAYLAND_DISPLAY') or not shutil.which('ffmpeg'):
    raise SystemExit('Execute na sessão Wayland, com Hyprland, Quickshell e ffmpeg instalados.')
review = Path(tempfile.mkdtemp(prefix='arch-lock-displays-'))
print('Capturas de teste:', review, flush=True)
with tempfile.TemporaryDirectory(prefix='arch-lock-display-check-') as task_dir:
    task = Path(task_dir)
    source = task / 'lock'
    shutil.copytree(args.source, source)
    shell = source / 'shell.qml'
    code = shell.read_text()
    code = code.replace('signal clearInput()', 'signal clearInput()\n    signal testCaptureRequested()')
    code = code.replace('function theme(): string', 'function capture(): void { root.testCaptureRequested(); }\n        function theme(): string')
    code = code.replace('WlSessionLockSurface {', 'WlSessionLockSurface {\n            id: outputSurface')
    capture = '''
                id: lockView
                Connections {
                    target: root
                    function onTestCaptureRequested(): void {
                        for (const child of lockView.children) {
                            if (child.objectName === "animation") {
                                const outputName = outputSurface.screen.name;
                                console.info("LOCKTEST_GEOMETRY", JSON.stringify({output: outputName, width: child.width, height: child.height}));
                                child.grabToImage(result => {
                                    result.saveToFile(OUTPUT_PREFIX + outputName + ".png");
                                    console.info("LOCKTEST_CAPTURED", outputName, child.width, child.height);
                                });
                            }
                        }
                    }
                }
'''.replace('OUTPUT_PREFIX', json.dumps(str(review) + '/'))
    code = code.replace('LockView {', 'LockView {\n' + capture)
    shell.write_text(code)
    config_root = task / 'config'
    current = config_root / 'theme/current'
    current.mkdir(parents=True)
    (current / 'palette.json').write_text(json.dumps({'theme':'nord','colors':{'background':'#191c23','darker_background':'#191c23','blue':'#81a1c1','cyan':'#88c0d0','foreground':'#d8dee9','green':'#a3be8c'}}))
    (current / 'hyprlock.conf').write_text('$font = monospace\n')
    hypr_config = task / 'hyprland.lua'
    hypr_config.write_text('''hl.monitor({output="",mode="1280x720@60",position="auto",scale=1})
hl.monitor({output="LOCKTEST-UW",mode="2560x1080@60",position="auto",scale=1})
hl.monitor({output="LOCKTEST-SCALED",mode="1920x1080@60",position="auto",scale=1.5})
hl.monitor({output="LOCKTEST-PORTRAIT",mode="1080x1920@60",position="auto",scale=1})
hl.config({animations={enabled=false},misc={disable_hyprland_logo=true,disable_splash_rendering=true}})
''')
    env = dict(os.environ)
    env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
    compositor_log = (task / 'compositor.log').open('w+')
    nested = subprocess.Popen(['Hyprland','-c',str(hypr_config)],env=env,stdout=compositor_log,stderr=subprocess.STDOUT)
    locker = None
    try:
        runtime = Path(os.environ['XDG_RUNTIME_DIR'])
        lock_file = None
        deadline = time.monotonic() + 12
        while nested.poll() is None and time.monotonic() < deadline:
            for candidate in (runtime/'hypr').glob('*/hyprland.lock'):
                lines = candidate.read_text().splitlines()
                if len(lines)>1 and lines[0]==str(nested.pid): lock_file=candidate; break
            if lock_file and (runtime/lock_file.read_text().splitlines()[1]).exists(): break
            time.sleep(.1)
        assert lock_file, 'Compositor de teste não iniciou.'
        env.update(WAYLAND_DISPLAY=lock_file.read_text().splitlines()[1],HYPRLAND_INSTANCE_SIGNATURE=lock_file.parent.name,
                   XDG_CONFIG_HOME=str(config_root),QT_QPA_PLATFORM='wayland',QS_DISABLE_CRASH_HANDLER='1')
        def hypr(*command):
            return subprocess.check_output(['hyprctl',*command],env=env,text=True,timeout=4)
        for output in ['LOCKTEST-UW','LOCKTEST-SCALED']:
            assert 'ok' in hypr('output','create','headless',output)
        time.sleep(.4)
        log_file = (task / 'locker.log').open('w+')
        locker = subprocess.Popen(['quickshell','-p',str(shell)],env=env,stdout=log_file,stderr=subprocess.STDOUT)
        def ipc(method):
            result = subprocess.run(['quickshell','-p',str(shell),'ipc','call','locker',method],env=env,capture_output=True,text=True,timeout=3)
            return result.stdout.strip() if result.returncode==0 else ''
        deadline = time.monotonic()+7
        while time.monotonic()<deadline and ipc('status')!='locked': time.sleep(.15)
        assert ipc('status')=='locked', 'Bloqueio inicial não confirmado.'
        assert 'ok' in hypr('output','create','headless','LOCKTEST-PORTRAIT')
        time.sleep(.8)
        assert ipc('status')=='locked', 'Bloqueio se perdeu com monitor adicionado.'
        monitors = json.loads(hypr('-j','monitors'))
        print('Monitores isolados:',[(m['name'],m['width'],m['height'],m['scale']) for m in monitors],flush=True)
        ipc('capture')
        deadline=time.monotonic()+5
        while len(list(review.glob('*.png')))<len(monitors) and time.monotonic()<deadline: time.sleep(.1)
        assert len(list(review.glob('*.png')))==len(monitors), 'Faltou uma superfície de bloqueio.'
        def check_image(monitor):
            path=review/(monitor['name']+'.png')
            width,height=struct.unpack('>II',path.read_bytes()[16:24])
            rgba=subprocess.check_output(['ffmpeg','-v','error','-i',str(path),'-frames:v','1','-f','rawvideo','-pix_fmt','rgba','pipe:1'],timeout=15)
            x,y=int(width*.95),int(height*.95)
            offset=(y*width+x)*4
            pixel=tuple(rgba[offset:offset+4])
            print(monitor['name'], 'captura', (width,height), 'borda inferior direita', pixel, flush=True)
            assert pixel[3]>25, 'Animação cortada: '+monitor['name']
        for monitor in monitors:
            check_image(monitor)
        # An existing screen can change resolution while the session is locked.
        hypr_config.write_text(hypr_config.read_text().replace('2560x1080@60', '3440x1440@60'))
        hypr('reload')
        deadline=time.monotonic()+5
        while time.monotonic()<deadline:
            changed=next(m for m in json.loads(hypr('-j','monitors')) if m['name']=='LOCKTEST-UW')
            if changed['width']==3440 and changed['height']==1440: break
            time.sleep(.1)
        assert changed['width']==3440 and changed['height']==1440, 'Monitor não redimensionou.'
        resized_image=review/'LOCKTEST-UW.png'
        resized_image.unlink()
        ipc('capture')
        deadline=time.monotonic()+5
        while time.monotonic()<deadline:
            log_output=(task/'locker.log').read_text()
            if 'LOCKTEST_CAPTURED LOCKTEST-UW 3440 1440' in log_output: break
            time.sleep(.2)
            ipc('capture')
        assert 'LOCKTEST_CAPTURED LOCKTEST-UW 3440 1440' in (task/'locker.log').read_text(), 'Faltou captura após redimensionar.'
        assert struct.unpack('>II',resized_image.read_bytes()[16:24])==(3440,1440), 'Captura manteve o tamanho anterior.'
        check_image(changed)
        assert ipc('status')=='locked', 'Bloqueio se perdeu com mudança de resolução.'
        assert 'ok' in hypr('output','remove','LOCKTEST-SCALED')
        time.sleep(.4)
        assert ipc('status')=='locked', 'Bloqueio se perdeu com monitor removido.'
        log_file.seek(0)
        output=log_file.read()
        (review/'locker.log').write_text(output)
        print(output,flush=True)
        assert not any(marker in output for marker in ['ERROR','ReferenceError','TypeError'])
        print('Múltiplas telas, escala mista, conexão/desconexão, redimensionamento e bordas: OK.',flush=True)
    finally:
        for child in [locker,nested]:
            if child and child.poll() is None:
                child.terminate()
                try: child.wait(timeout=4)
                except subprocess.TimeoutExpired: child.kill(); child.wait()
