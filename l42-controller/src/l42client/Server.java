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

        var result = client.runL42();

        var response = new JSONObject();
        response.put("ok", true);
        response.put("stdout", "STDOUT HERE");
        response.put("stderr", "STDERR HERE");
        response.put("returncode", 0);
        response.put("duration", result.executionTime());
        return response;
    }

    Server(L42Client client) {
        this(client, 8000);
    }

    Server(L42Client client, int port) {
        this(client, "localhost", port);
    }

    Server(L42Client client, String bind, int port) {
        try {
            this.client = client;
            httpServer = HttpServer.create(new InetSocketAddress(bind, port), 0);
            httpServer.createContext("/health", new HealthHttpHandler());
            httpServer.createContext("/api", new ApiHttpHandler(this.client));
            httpServer.setExecutor(null); // default executor
            httpServer.start();
            var baseUrl = "http://" + bind + ":" + port + "/";
            System.err.println("Listening on " + baseUrl);
            System.err.println("Health: " + baseUrl + "health");
            System.err.println("42 API: " + baseUrl + "api");
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
}
