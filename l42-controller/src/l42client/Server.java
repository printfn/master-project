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

        var responseJson = Server.handleApi(requestJson);

        Server.respond(200, responseJson.toString(), exchange);
    }
}

public class Server {
    HttpServer httpServer;

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

    static JSONObject handleApi(JSONObject request) {
        var code = request.getString("code");
        System.err.println("Received code:\n" + code);

        var response = new JSONObject();
        response.put("ok", true);
        response.put("stdout", "STDOUT HERE");
        response.put("stderr", "STDERR HERE");
        response.put("returncode", 0);
        response.put("duration", 1);
        return response;
    }

    Server() {
        this(8000);
    }

    Server(int port) {
        this("localhost", port);
    }

    Server(String bind, int port) {
        try {
            httpServer = HttpServer.create(new InetSocketAddress(bind, port), 0);
            httpServer.createContext("/health", new HealthHttpHandler());
            httpServer.createContext("/api", new ApiHttpHandler());
            httpServer.setExecutor(null);
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
