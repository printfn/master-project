package l42server;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpHandler;
import com.amazonaws.lambda.thirdparty.org.json.JSONObject;

import java.io.IOException;
import java.nio.charset.StandardCharsets;

class ExecuteHandler implements HttpHandler {
    L42 client;

    ExecuteHandler(L42 client) {
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
