import App
import Vapor
import Smtp

var env = try Environment.detect()
try LoggingSystem.bootstrap(from: &env)
let app = Application(env)
defer { app.shutdown() }

app.smtp.configuration.hostname = "w00aa501.kasserver.com"
app.smtp.configuration.username = "m051b685"
app.smtp.configuration.password = "YKDnmVe4AK5fdy5c"
app.smtp.configuration.secure = .ssl

try configure(app)
try app.run()
