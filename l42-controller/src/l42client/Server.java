package l42client;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;
import org.json.JSONObject;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

class HealthHttpHandler implements HttpHandler {
    @Override
    public void handle(HttpExchange exchange) throws IOException {
        Server.respond(200, "It works!", exchange);
    }
}

class ApiHttpHandler implements HttpHandler {
    L42Client client;

    ApiHttpHandler(L42Client client) {
        this.client = client;
    }

    @Override
    public void handle(HttpExchange exchange) throws IOException {
        if (!exchange.getRequestMethod().equals("POST")) {
            Server.respond(405, "Method Not Allowed", exchange);
            return;
        }
        var requestBodyStream = exchange.getRequestBody();
        var requestBody = new String(requestBodyStream.readAllBytes(), StandardCharsets.UTF_8);
        requestBodyStream.close();
        var requestJson = new JSONObject(requestBody);

        var responseJson = Server.handleApi(requestJson, client);

        Server.respond(200, responseJson.toString(), exchange);
    }
}

public class Server {
    HttpServer httpServer;
    L42Client client;
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

    static JSONObject handleApi(JSONObject request, L42Client client) {
        var code = request.getString("code");
        System.err.println("Received code:\n" + code);
        return client.runL42FromCode(code).toJSON();
    }

    Server(L42Client client, int port, boolean warmCache) {
        final var bind = "0.0.0.0";
        try {
            this.client = client;
            if (warmCache) {
                client.runL42FromCode(HELLO_WORLD);
            }
            httpServer = HttpServer.create(new InetSocketAddress(bind, port), 0);
            httpServer.createContext("/health", new HealthHttpHandler());
            httpServer.createContext("/", new ApiHttpHandler(this.client));
            httpServer.setExecutor(null); // default executor
            httpServer.start();
            var baseUrl = "http://" + bind + ":" + port + "/";
            System.err.println("Listening on " + baseUrl);
            System.err.println("Health: " + baseUrl + "health");
            System.err.println("42 API: " + baseUrl);
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
}
