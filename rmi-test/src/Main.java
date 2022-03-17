import java.net.URI;
import java.net.URISyntaxException;

public class Main {

    public static void main(String[] args) {
        URI projectLocation;
        try {
            projectLocation = new URI(
                    "file:///Users/printfn/Code/master-project/master-project/l42-examples/Point");
        } catch (URISyntaxException e) {
            e.printStackTrace();
            return;
        }

        var client = new L42Client(projectLocation);

        System.out.println("Run #1:");
        System.out.println(client.runL42().formatOutput());
        System.out.println("Run #2:");
        System.out.println(client.runL42().formatOutput());
        System.out.println("Reached end of main()");
    }
}
