import QtQml

// The PAM transport is injected so that failure paths can be tested without real credentials.
QtObject {
    id: auth
    required property var pam
    property bool secure: false
    property bool authenticating: false
    property bool answerSent: false
    property string pendingPassword: ""
    property string errorMessage: ""
    readonly property bool busy: authenticating || pam.active

    signal clearInput()
    signal authenticated()

    function clear(): void {
        pendingPassword = "";
        errorMessage = "";
        clearInput();
    }

    function submit(password: string): void {
        if (!secure || busy || password.length === 0)
            return;
        errorMessage = "";
        pendingPassword = password;
        answerSent = false;
        authenticating = true;
        clearInput();
        if (!pam.start()) {
            pendingPassword = "";
            authenticating = false;
            errorMessage = "Não foi possível verificar a senha. Tente novamente.";
        }
    }

    function respondToPrompt(required: bool, visible: bool): void {
        if (!required)
            return;
        if (!authenticating || answerSent || visible) {
            pendingPassword = "";
            authenticating = false;
            errorMessage = "Método de autenticação não suportado nesta tela.";
            pam.abort();
            return;
        }
        answerSent = true;
        const password = pendingPassword;
        pendingPassword = "";
        pam.respond(password);
    }

    function complete(success: bool, serviceError: bool): bool {
        const allowed = authenticating && answerSent && success && secure;
        pendingPassword = "";
        authenticating = false;
        answerSent = false;
        clearInput();
        if (allowed) {
            authenticated();
        } else {
            errorMessage = serviceError
                ? "Falha na autenticação. Verifique o serviço de bloqueio."
                : "Senha incorreta ou acesso temporariamente bloqueado.";
        }
        return allowed;
    }
}
