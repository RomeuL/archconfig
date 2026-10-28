import QtQml
import QtTest
import "../../home/.config/quickshell/arch-lock"

TestCase {
    name: "LockAuthentication"

    QtObject {
        id: transport
        property bool active: false
        property bool canStart: true
        property string answer: ""
        property int starts: 0
        property int aborts: 0
        function start(): bool { starts++; active = canStart; return canStart; }
        function respond(value: string): void { answer = value; }
        function abort(): void { aborts++; active = false; }
    }

    AuthController { id: auth; pam: transport }
    SignalSpy { id: unlocked; target: auth; signalName: "authenticated" }

    function init() {
        transport.active = false;
        transport.canStart = true;
        transport.answer = "";
        transport.starts = 0;
        transport.aborts = 0;
        auth.secure = true;
        auth.authenticating = false;
        auth.answerSent = false;
        auth.clear();
        unlocked.clear();
    }

    function begin() {
        auth.submit("example-test-value");
        auth.respondToPrompt(true, false);
    }

    function test_unsecured_session_and_empty_input_do_not_start_pam() {
        auth.secure = false;
        auth.submit("example");
        auth.secure = true;
        auth.submit("");
        compare(transport.starts, 0);
        compare(unlocked.count, 0);
    }

    function test_failed_start_erases_pending_password() {
        transport.canStart = false;
        auth.submit("example");
        compare(auth.pendingPassword, "");
        compare(auth.busy, false);
        verify(auth.errorMessage.length > 0);
        compare(unlocked.count, 0);
    }

    function test_password_sent_once_and_not_retained() {
        begin();
        compare(transport.answer, "example-test-value");
        compare(auth.pendingPassword, "");
        auth.respondToPrompt(true, false);
        compare(transport.aborts, 1);
        verify(!auth.complete(true, false));
        compare(unlocked.count, 0);
    }

    function test_visible_pam_prompt_never_receives_password() {
        auth.submit("example");
        auth.respondToPrompt(true, true);
        compare(transport.answer, "");
        compare(auth.pendingPassword, "");
        compare(transport.aborts, 1);
        verify(!auth.complete(true, false));
    }

    function test_wrong_password_does_not_unlock() {
        begin();
        verify(!auth.complete(false, false));
        compare(unlocked.count, 0);
        compare(auth.pendingPassword, "");
        verify(auth.errorMessage.length > 0);
    }

    function test_only_requested_success_after_response_unlocks() {
        verify(!auth.complete(true, false));
        auth.submit("example");
        verify(!auth.complete(true, false));
        transport.active = false;
        begin();
        verify(auth.complete(true, false));
        compare(unlocked.count, 1);
        // A repeated completion or a stale callback must not unlock again.
        verify(!auth.complete(true, false));
        compare(unlocked.count, 1);
    }

    function test_lost_compositor_lock_refuses_success() {
        begin();
        auth.secure = false;
        verify(!auth.complete(true, false));
        compare(unlocked.count, 0);
    }

    function test_repeated_enter_does_not_start_second_attempt() {
        auth.submit("first-example");
        auth.submit("second-example");
        auth.respondToPrompt(true, false);
        compare(transport.starts, 1);
        compare(transport.answer, "first-example");
    }
}
