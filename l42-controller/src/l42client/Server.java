package l42client;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.sun.net.httpserver.HttpServer;

import java.io.IOException;
import java.net.InetSocketAddress;
import java.nio.charset.StandardCharsets;

class HealthHttpHandler implements HttpHandler {
    @Override
    public void handle(HttpExchange exchange) throws IOException {
        var response = "It works!";
        exchange.sendResponseHeaders(200, response.length());
        var stream = exchange.getResponseBody();
        stream.write(response.getBytes(StandardCharsets.UTF_8));
        stream.close();
    }
}

public class Server {
    HttpServer httpServer;

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
            httpServer.setExecutor(null);
            httpServer.start();
            System.err.println("Listening on http://" + bind + ":" + port + "/");
        } catch (IOException e) {
            e.printStackTrace();
            throw new RuntimeException(e);
        }
    }
}
