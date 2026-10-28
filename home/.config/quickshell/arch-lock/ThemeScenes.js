.pragma library

// Native Canvas scenes: deterministic motion, theme colors, no external assets or processes.
var catalog = {
    "tron-arcade": {title: "TRON ARCADE", scene: "ARENA DE LUZ", draw: tron},
    "cyber-arch": {title: "CYBER ARCH", scene: "DISTRITO NEON", draw: cyber},
    "tokyo-night": {title: "TOKYO NIGHT", scene: "ÚLTIMO TREM", draw: tokyo},
    "catppuccin": {title: "CATPPUCCIN", scene: "CAFÉ CÓSMICO", draw: catppuccin},
    "catppuccin-latte": {title: "CATPPUCCIN LATTE", scene: "CAFÉ DA MANHÃ", draw: latte},
    "gruvbox": {title: "GRUVBOX", scene: "OFICINA ANALÓGICA", draw: gruvbox},
    "nord": {title: "NORD", scene: "AURORA BOREAL", draw: nord},
    "rose-pine": {title: "ROSÉ PINE", scene: "JARDIM DE PÉTALAS", draw: rose},
    "kanagawa": {title: "KANAGAWA", scene: "MARÉ DO PACÍFICO", draw: kanagawa},
    "everforest": {title: "EVERFOREST", scene: "FLORESTA DOS VAGALUMES", draw: everforest}
};

function info(theme) {
    return catalog[theme] || {title: "CÉU NOTURNO", scene: "CONSTELAÇÕES", draw: stars};
}

function noise(seed) {
    var value = Math.sin(seed * 127.1 + 311.7) * 43758.5453;
    return value - Math.floor(value);
}

function color(p, key, fallback) { return p[key] || fallback; }

function line(c, points, ink, alpha, width) {
    c.strokeStyle = ink;
    c.globalAlpha = alpha;
    c.lineWidth = width || 1;
    c.beginPath();
    for (var i = 0; i < points.length; i++) {
        if (i === 0) c.moveTo(points[i][0], points[i][1]);
        else c.lineTo(points[i][0], points[i][1]);
    }
    c.stroke();
}

function polygon(c, points, ink, alpha) {
    c.fillStyle = ink;
    c.globalAlpha = alpha;
    c.beginPath();
    c.moveTo(points[0][0], points[0][1]);
    for (var i = 1; i < points.length; i++) c.lineTo(points[i][0], points[i][1]);
    c.closePath();
    c.fill();
}

function rect(c, x, y, w, h, ink, alpha) {
    c.fillStyle = ink;
    c.globalAlpha = alpha === undefined ? 1 : alpha;
    c.fillRect(Math.round(x), Math.round(y), Math.round(w), Math.round(h));
}

function circle(c, x, y, r, ink, alpha, stroke) {
    c.globalAlpha = alpha;
    c.beginPath();
    c.arc(x, y, r, 0, Math.PI * 2);
    if (stroke) { c.strokeStyle = ink; c.lineWidth = stroke; c.stroke(); }
    else { c.fillStyle = ink; c.fill(); }
}

function sprite(c, rows, x, y, size, ink, alpha) {
    for (var row = 0; row < rows.length; row++) {
        for (var col = 0; col < rows[row].length; col++) {
            if (rows[row][col] === "1") rect(c, x + col * size, y + row * size, size, size, ink, alpha);
        }
    }
}

function starfield(c, w, h, t, ink, count) {
    for (var i = 0; i < count; i++) {
        var glow = 0.15 + 0.4 * (0.5 + 0.5 * Math.sin(t * 0.7 + i));
        rect(c, noise(i * 2) * w, noise(i * 2 + 1) * h, i % 9 === 0 ? 3 : 2, 2, ink, glow);
    }
}

function paint(c, w, h, elapsed, theme, palette) {
    c.save();
    c.clearRect(0, 0, w, h);
    // Keep circles round and expand the composition on ultrawide displays.
    var scale = h / 720;
    c.scale(scale, scale);
    info(theme).draw(c, w / scale, 720, elapsed + 6, palette);
    c.restore();
}

function pathAt(points, distance) {
    var total = 0;
    for (var i = 1; i < points.length; i++) total += Math.abs(points[i][0] - points[i - 1][0]) + Math.abs(points[i][1] - points[i - 1][1]);
    distance = ((distance % total) + total) % total;
    for (var j = 1; j < points.length; j++) {
        var a = points[j - 1], b = points[j];
        var length = Math.abs(b[0] - a[0]) + Math.abs(b[1] - a[1]);
        if (distance <= length) return [a[0] + (b[0] - a[0]) * distance / length, a[1] + (b[1] - a[1]) * distance / length, Math.atan2(b[1] - a[1], b[0] - a[0])];
        distance -= length;
    }
    return [points[0][0], points[0][1], 0];
}

function lightcycle(c, route, distance, ink) {
    var trail = [];
    for (var step = 0; step <= 75; step++) trail.push(pathAt(route, distance - 450 + step * 6));
    line(c, trail, ink, 0.08, 13);
    line(c, trail, ink, 0.28, 5);
    line(c, trail, ink, 0.95, 2);
    var head = pathAt(route, distance);
    c.save();
    c.translate(head[0], head[1]);
    c.rotate(head[2]);
    sprite(c, ["01110001110", "11111111111", "00111111100", "11111111111", "01110001110"], -11, -5, 2, ink, 1);
    rect(c, -5, -1, 10, 2, "#ffffff", 0.95);
    c.restore();
}

function tron(c, w, h, t, p) {
    var cyan = color(p, "cyan", "#00e5ff"), orange = color(p, "orange", "#ff9e1b");
    var horizon = 245;
    for (var x = -w; x < w * 2; x += 100) line(c, [[w / 2, horizon], [x, h]], cyan, 0.18, 1);
    for (var i = 0; i < 18; i++) {
        var depth = (i / 18 + t * 0.018) % 1;
        var y = horizon + depth * depth * (h - horizon);
        line(c, [[0, y], [w, y]], cyan, 0.07 + depth * 0.22, 1);
    }
    line(c, [[0, horizon], [w, horizon]], cyan, 0.55, 2);
    circle(c, w / 2, 205, 63, cyan, 0.08, 14);
    circle(c, w / 2, 205, 63, cyan, 0.8, 2);
    circle(c, w / 2, 205, 48, orange, 0.65, 2);
    for (var tick = 0; tick < 4; tick++) {
        var a = t * 0.45 + tick * Math.PI / 2;
        line(c, [[w / 2 + Math.cos(a) * 46, 205 + Math.sin(a) * 46], [w / 2 + Math.cos(a) * 66, 205 + Math.sin(a) * 66]], cyan, 0.9, 4);
    }
    var routeA = [[w*.12,570],[w*.37,570],[w*.37,390],[w*.64,390],[w*.64,610],[w*.87,610],[w*.87,310],[w*.12,310],[w*.12,570]];
    var routeB = [[w*.8,530],[w*.56,530],[w*.56,340],[w*.23,340],[w*.23,625],[w*.94,625],[w*.94,285],[w*.8,285],[w*.8,530]];
    lightcycle(c, routeA, t * 95, cyan);
    lightcycle(c, routeB, t * 83 + 700, orange);
}

function buildings(c, w, t, p, cyberpunk) {
    var base = cyberpunk ? 565 : 570;
    for (var layer = 0; layer < 2; layer++) {
        for (var i = 0; i < Math.ceil(w / 56); i++) {
            var x = i * 58 + layer * 23;
            var height = 60 + noise(i * 5 + layer * 57) * (cyberpunk ? 280 : 190);
            var top = base - height + layer * 28;
            rect(c, x, top, 49, height, color(p, layer ? "blue" : "magenta", "#7aa2f7"), layer ? 0.18 : 0.08);
            for (var y = top + 12; y < base; y += 17) {
                for (var col = 0; col < 4; col++) {
                    if (noise(i * 400 + col * 7 + Math.floor(y)) > 0.5)
                        rect(c, x + 6 + col * 10, y, 3, 5, color(p, col % 2 ? "cyan" : "yellow", "#ffe14d"), 0.3 + 0.2 * Math.sin(t * 0.2 + i));
                }
            }
            if (cyberpunk && i % 4 === 0) {
                rect(c, x + 12, top + 22, 6, 45, color(p, "red", "#ff003c"), 0.85);
                rect(c, x + 22, top + 22, 15, 3, color(p, "cyan", "#00f0ff"), 0.75);
            }
        }
    }
}

function cyber(c, w, h, t, p) {
    var cyan = color(p, "cyan", "#00f0ff"), red = color(p, "red", "#ff003c");
    buildings(c, w, t, p, true);
    for (var i = 0; i < 80; i++) {
        var x = noise(i) * w, y = (noise(i + 100) * h + t * (90 + noise(i) * 50)) % h;
        line(c, [[x, y], [x - 5, y + 17]], cyan, 0.12, 1);
    }
    for (var bar = 0; bar < 28; bar++) {
        rect(c, noise(bar + 10) * w + Math.sin(t + bar) * 8, 570 + noise(bar + 20) * 90, 12 + noise(bar) * 100, 2, bar % 2 ? red : cyan, 0.25);
    }
    var dx = ((t * 42) % (w + 140)) - 70, dy = 205 + Math.sin(t * 0.7) * 24;
    line(c, [[dx - 25, dy], [dx + 25, dy]], red, 0.8, 2);
    polygon(c, [[dx - 11, dy], [dx, dy + 9], [dx + 11, dy]], cyan, 0.9);
    polygon(c, [[dx, dy + 10], [dx - 30, 560], [dx + 55, 560]], cyan, 0.04);
}

function tokyo(c, w, h, t, p) {
    starfield(c, w, 340, t, color(p, "magenta", "#ad8ee6"), 42);
    circle(c, w * .73, 190, 43, color(p, "magenta", "#ad8ee6"), 0.15);
    circle(c, w * .73, 190, 32, color(p, "foreground", "#c0caf5"), 0.65);
    buildings(c, w, t, p, false);
    var tower = w * .43;
    polygon(c, [[tower,250],[tower-36,535],[tower+36,535]], color(p,"red","#f7768e"), .25);
    for (var step = 0; step < 7; step++) line(c, [[tower-step*5,290+step*36],[tower+step*5,290+step*36]], color(p,"red","#f7768e"), .65, 2);
    line(c, [[0,580],[w,580]], color(p,"blue","#7aa2f7"), .7, 3);
    for (var pier = 0; pier < w; pier += 140) rect(c,pier,584,8,55,color(p,"blue","#7aa2f7"),.2);
    var train = ((t * 55) % (w + 410)) - 410;
    for (var car = 0; car < 4; car++) {
        rect(c, train + car * 97, 554, 92, 22, color(p,"magenta","#ad8ee6"), .7);
        for (var window = 0; window < 6; window++) rect(c,train+car*97+8+window*13,558,8,8,color(p,"yellow","#e0af68"),.9);
        rect(c,train+car*97,574,92,2,color(p,"cyan","#449dab"),.9);
    }
    var comet = (t * 22) % (w + 400) - 200;
    line(c, [[comet,100],[comet+65,122]], color(p,"foreground","#c0caf5"),.45,1);
}

function mug(c, x, y, t, p, scale) {
    c.save(); c.translate(x,y); c.scale(scale,scale);
    var ink = color(p,"magenta","#f5c2e7");
    rect(c,-45,0,90,60,ink,.65); rect(c,-36,56,72,8,ink,.65);
    circle(c,49,23,19,ink,.65,6);
    line(c,[[-58,73],[61,73]],color(p,"foreground","#cdd6f4"),.5,3);
    for (var steam=0; steam<3; steam++) {
        var points=[];
        for(var n=0;n<24;n++) points.push([-24+steam*24+Math.sin(n*.25+t*1.2+steam)*7,-10-n*2]);
        line(c,points,color(p,"foreground","#cdd6f4"),.25,2);
    }
    c.restore();
}

var sleepingCat = ["011000000110", "111100001111", "111111111111", "111111111111", "110011110011", "111111111111", "011111111110", "001111111100"];

function catppuccin(c,w,h,t,p) {
    var pink=color(p,"magenta","#f5c2e7"), blue=color(p,"blue","#89b4fa");
    starfield(c,w,610,t,pink,65);
    circle(c,w*.5,375,185,blue,.17,1); circle(c,w*.5,375,205,pink,.13,1);
    circle(c,w*.5,375,145,blue,.07);
    mug(c,w*.5-65,395+Math.sin(t*.65)*8,t,p,1.15);
    sprite(c,sleepingCat,w*.5+45,408+Math.sin(t*.65)*8,5,color(p,"yellow","#f9e2af"),.85);
    for(var i=0;i<3;i++) {
        var a=t*.12+i*2.1;
        circle(c,w*.5+Math.cos(a)*205,375+Math.sin(a)*135,9+i*3,color(p,i===1?"green":"magenta",pink),.7);
    }
    c.font="16px monospace"; c.fillStyle=pink; c.globalAlpha=.65;
    for(var z=0;z<3;z++) c.fillText("z",w*.5+90+z*17,380-z*17-Math.sin(t+z)*5);
}

function cloud(c,x,y,ink,alpha) {
    rect(c,x,y,96,16,ink,alpha); rect(c,x+16,y-13,60,14,ink,alpha); rect(c,x+32,y-22,28,10,ink,alpha);
}

function latte(c,w,h,t,p) {
    var blue=color(p,"blue","#1e66f5"), orange=color(p,"orange","#d84e2b"), green=color(p,"green","#40a02b"), x=w*.5-235;
    rect(c,x,185,470,330,blue,.06);
    line(c,[[x,515],[x,185],[x+470,185],[x+470,515]],blue,.4,4);
    line(c,[[x+235,185],[x+235,515]],blue,.3,3); line(c,[[x,340],[x+470,340]],blue,.3,3);
    circle(c,w*.5+120,267,39,color(p,"yellow","#df8e1d"),.65);
    for(var i=0;i<3;i++) cloud(c,x+((t*9+i*100)%340),245+i*61,color(p,"magenta","#ea76cb"),.13);
    rect(c,x-45,515,560,10,orange,.35);
    mug(c,w*.5-75,442,t,p,.8);
    sprite(c,sleepingCat,w*.5+57,474,4,orange,.75);
    rect(c,x+13,465,36,48,orange,.65);
    for(var leaf=0;leaf<5;leaf++) {
        var lx=x+31+Math.sin(leaf*2+t*.25)*20, ly=420+leaf*8;
        line(c,[[x+31,466],[lx,ly]],green,.6,2);
        polygon(c,[[lx,ly],[lx-16,ly-12],[lx-4,ly+8]],green,.55);
    }
}

function gear(c,x,y,r,teeth,angle,ink) {
    c.save(); c.translate(x,y); c.rotate(angle);
    var points=[];
    for(var i=0;i<teeth*4;i++) {
        var a=i*Math.PI*2/(teeth*4), radius=i%4<2?r:r*.86;
        points.push([Math.cos(a)*radius,Math.sin(a)*radius]);
    }
    points.push(points[0]); line(c,points,ink,.65,3);
    circle(c,0,0,r*.62,ink,.3,2); circle(c,0,0,r*.16,ink,.8,3);
    for(var j=0;j<4;j++) {var b=j*Math.PI/2;line(c,[[Math.cos(b)*r*.2,Math.sin(b)*r*.2],[Math.cos(b)*r*.58,Math.sin(b)*r*.58]],ink,.45,4);}
    c.restore();
}

function gruvbox(c,w,h,t,p) {
    var amber=color(p,"yellow","#d8a657"), green=color(p,"green","#a9b665");
    gear(c,w*.5-115,345,112,16,t*.13,amber);
    gear(c,w*.5+70,345,78,12,-t*.18+.15,color(p,"orange","#e1875c"));
    gear(c,w*.5+167,445,59,10,t*.24,green);
    line(c,[[w*.2,565],[w*.8,565]],amber,.2,1);
    for(var x=0;x<400;x+=5) {
        var signal=Math.sin(x*.04-t*1.1)*Math.sin(x*.009+t*.3);
        rect(c,w*.5-200+x,568+signal*27,3,3,green,.7);
    }
    for(var dot=0;dot<20;dot++) rect(c,w*.5-190+dot*20,620,3,3,amber,.4);
}

function nord(c,w,h,t,p) {
    var cyan=color(p,"cyan","#88c0d0"), green=color(p,"green","#a3be8c"), blue=color(p,"blue","#81a1c1");
    starfield(c,w,420,t,color(p,"foreground","#d8dee9"),65);
    for(var band=0;band<3;band++) {
        for(var x=0;x<w;x+=5) {
            var y=220+band*35+Math.sin(x*.006+t*.2+band)*44+Math.sin(x*.012-t*.13)*20;
            var length=70+35*Math.sin(x*.009+t*.2+band), fade=.06+.15*(.5+.5*Math.sin(x*.004+t*.3+band));
            line(c,[[x,y],[x,y+length]],band===0?green:(band===1?cyan:blue),fade,3);
        }
    }
    polygon(c,[[0,570],[w*.16,385],[w*.28,520],[w*.47,330],[w*.66,540],[w*.81,405],[w,570],[w,h],[0,h]],blue,.2);
    polygon(c,[[w*.385,425],[w*.47,330],[w*.545,420],[w*.48,392],[w*.45,408]],color(p,"foreground","#d8dee9"),.45);
    polygon(c,[[0,650],[w*.18,520],[w*.35,610],[w*.64,450],[w*.85,590],[w,510],[w,h],[0,h]],cyan,.12);
    for(var snow=0;snow<50;snow++) rect(c,(noise(snow)*w+t*7)%w,(noise(snow+100)*h+t*(8+noise(snow)*12))%h,2,2,color(p,"foreground","#d8dee9"),.35);
}

function rose(c,w,h,t,p) {
    var ink=color(p,"red","#b4637a"), pine=color(p,"green","#286983"), gold=color(p,"yellow","#ea9d34");
    circle(c,w*.58,235,48,gold,.18); circle(c,w*.58,235,41,gold,.25,1);
    line(c,[[w*.19,565],[w*.25,380],[w*.34,294],[w*.42,265]],pine,.5,7);
    line(c,[[w*.24,410],[w*.17,345],[w*.12,330]],pine,.45,4);
    line(c,[[w*.29,345],[w*.37,355],[w*.45,320]],pine,.45,4);
    for(var flower=0;flower<38;flower++) {
        var fx=w*.13+noise(flower)*w*.31, fy=272+noise(flower+55)*112;
        for(var petal=0;petal<5;petal++) {var a=petal*Math.PI*2/5;circle(c,fx+Math.cos(a)*5,fy+Math.sin(a)*5,4,ink,.4);}
        rect(c,fx,fy,2,2,gold,.8);
    }
    for(var ripple=0;ripple<8;ripple++) {
        var y=535+ripple*13, half=30+ripple*15+Math.sin(t*.6+ripple)*8;
        line(c,[[w*.59-half,y],[w*.59+half,y]],pine,.2,1);
    }
    for(var i=0;i<28;i++) {
        var x=(noise(i)*w+t*(8+noise(i+3)*10))%w, py=(noise(i+50)*h+t*14)%h;
        c.save(); c.translate(x,py); c.rotate(t*.5+i); rect(c,-3,-2,7,4,ink,.6); c.restore();
    }
}

function kanagawa(c,w,h,t,p) {
    var blue=color(p,"blue","#7e9cd8"), foam=color(p,"foreground","#dcd7ba"), red=color(p,"red","#c34043");
    circle(c,w*.71,240,51,red,.65);
    polygon(c,[[w*.7,470],[w*.84,280],[w*.98,470]],blue,.18);
    polygon(c,[[w*.80,335],[w*.84,280],[w*.88,335],[w*.85,322],[w*.83,330]],foam,.55);
    for(var layer=0;layer<5;layer++) {
        var points=[[0,h]], crest=[];
        for(var x=0;x<=w+8;x+=8) {
            var y=440+layer*38+Math.sin(x*.009-t*.65+layer*.7)*(22+layer*3)+Math.sin(x*.018+t*.35)*9;
            points.push([x,y]); crest.push([x,y]);
        }
        points.push([w,h]); polygon(c,points,blue,.12+layer*.045); line(c,crest,foam,.2+layer*.04,2);
    }
    // Curled foam and a distant mountain echo Japanese woodblock waves.
    for(var ring=0;ring<5;ring++) {
        c.beginPath(); c.globalAlpha=.4-ring*.045; c.strokeStyle=foam; c.lineWidth=3;
        c.arc(w*.35,413+Math.sin(t*.65)*12,83+ring*11,Math.PI*.8,Math.PI*1.92); c.stroke();
    }
    for(var spray=0;spray<24;spray++) {
        var phase=(noise(spray)+t*.16)%1;
        rect(c,w*.35+40+phase*100,350-Math.sin(phase*Math.PI)*65+noise(spray)*30,3,3,foam,(1-phase)*.65);
    }
    var boatY=545+Math.sin(t*.65)*12;
    polygon(c,[[w*.61-47,boatY],[w*.61+47,boatY],[w*.61+30,boatY+13],[w*.61-25,boatY+13]],color(p,"yellow","#c0a36e"),.65);
}

function pine(c,x,y,height,ink,alpha,sway) {
    rect(c,x-3,y-height,6,height,ink,alpha);
    for(var layer=0;layer<5;layer++) {
        var top=y-height+layer*height*.15, half=height*(.09+layer*.035);
        polygon(c,[[x+sway,top],[x-half,top+height*.29],[x+half,top+height*.29]],ink,alpha);
    }
}

function everforest(c,w,h,t,p) {
    var green=color(p,"green","#a7c080"), cyan=color(p,"cyan","#83c092"), gold=color(p,"yellow","#dbbc7f");
    for(var layer=0;layer<3;layer++) {
        for(var tree=0;tree<9;tree++) {
            var x=tree*w/8+noise(tree+layer*19)*30;
            pine(c,x,590+layer*25,175+noise(tree*7+layer)*170,layer===1?cyan:green,.09+layer*.07,Math.sin(t*.3+tree)*3);
        }
    }
    for(var mist=0;mist<5;mist++) {
        var mx=((t*8+mist*220)%(w+260))-260;
        line(c,[[mx,510+mist*21],[mx+230,510+mist*21]],cyan,.05,12);
    }
    for(var fly=0;fly<45;fly++) {
        var fx=noise(fly)*w+Math.sin(t*.4+fly)*25, fy=340+noise(fly+20)*250+Math.cos(t*.5+fly)*18;
        var glow=.15+.65*Math.pow(.5+.5*Math.sin(t*1.2+fly),3);
        circle(c,fx,fy,7,gold,glow*.08); rect(c,fx,fy,3,3,gold,glow);
    }
}

function stars(c,w,h,t,p) {
    var ink=color(p,"accent","#81a1c1");
    starfield(c,w,h,t,ink,100);
    for(var i=0;i<12;i++) {
        var x=w*.3+noise(i)*w*.4, y=240+noise(i+12)*240;
        line(c,[[x,y],[x+Math.sin(t*.1+i)*80,y+Math.cos(t*.1+i)*80]],ink,.2,1);
    }
}
