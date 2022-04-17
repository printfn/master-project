package l42server;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import com.amazonaws.lambda.thirdparty.org.json.JSONObject;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

class Server {
    HttpServer httpServer;
    L42 l42;
    static String HELLO_WORLD = """
            reuse [L42.is/AdamsTowel]
            Main=(
              Debug(S"Hello world from 42")
              )""";

    static void respond(int code, String response, HttpExchange exchange) {
        try {
            exchange.getResponseHeaders().add("Access-Control-Allow-Origin", "*");
            exchange.sendResponseHeaders(code, response.length());
            var stream = exchange.getResponseBody();
            stream.write(response.getBytes(StandardCharsets.UTF_8));
            stream.close();
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }

    static JSONObject handleApi(JSONObject request, L42 client) {
        var code = request.getString("code");
        System.err.println("Received code:\n" + code);
        return client.runL42FromCode(code).toJSON();
    }

    Server(L42 l42, int port, boolean warmCache) {
        final var bind = "0.0.0.0";
        try {
            this.l42 = l42;
            if (warmCache) {
                l42.runL42FromCode(HELLO_WORLD);
            }
            httpServer = HttpServer.create(new InetSocketAddress(bind, port), 0);
            httpServer.createContext("/health", new HealthHandler());
            httpServer.createContext("/execute", new ExecuteHandler(this.l42));
            httpServer.setExecutor(null); // default executor
            httpServer.start();
            var baseUrl = "http://" + bind + ":" + port + "/";
            System.err.println("Listening on " + baseUrl);
            System.err.println("Health: " + baseUrl + "health");
            System.err.println("Execute: " + baseUrl + "execute");
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
}
