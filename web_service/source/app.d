module app;

import std;

// Docs: https://github.com/ikod/dlang-requests

// Docs: https://trikko.github.io/serverino/
// Tips and tricks: https://github.com/trikko/serverino/wiki/
// Examples: https://github.com/trikko/serverino/tree/master/examples
import serverino;

enum ip_add = "10.1.1.49";

mixin ServerinoMain;

@onServerInit ServerinoConfig setup()
{
   ServerinoConfig sc = ServerinoConfig.create(); // Config with default params
   sc.addListener(ip_add, 8080);
   //sc.addListener("0.0.0.0", 8080);
   sc.setWorkers(4);

   return sc;
}

// Accept a new connection only if the request path is "/echo"
@onWebSocketUpgrade bool onUpgrade(Request req) {
	return req.path == "/echo";
}

void send_text(WebSocket ws, string text) {
    ws.send(text);
}

void process_file(WebSocket ws, const(ubyte[]) filedata) {
    import std.stdio : File, writeln;
    import core.thread;

    auto tmp = new File("tmp.pdf", "w");
    tmp.rawWrite(filedata);
    tmp.close();
    ws.send("File processed and you will be redirected to the Payment portal");
    Thread.sleep(100.msecs);
}

// Handle the WebSocket connection
@endpoint void echo(Request r, WebSocket ws) {
    import std.algorithm: canFind;

    ws.onTextMessage = (text) {
        log("Recieved text:", text);
        if (text.canFind("bill")) {
            send_text(ws, "Please upload the photo of your bill and press 'Upload' button.");
        } else {
            send_text(ws, "This is not request for the bill payment. Please wait your order in the queue.");
        }

        return false;
    };

    ws.onBinaryMessage = (file) {
        log("Recieved file");
        process_file(ws, file);

        return false;
    };

    ws.onCloseMessage = (msg) {
        import core.stdc.stdlib;

        log("Goodbye");
        //exit(0);

        return false;
    };

    ws.socket.blocking = true;
	// Read messages from the client
	while (true) {
        ws.receiveMessage();
	}
}

void gen_new_code() {
    import qr;

    QrCode("http://"~ip_add~":8080/assistant").saveAs("static/images/current_code.png");
}

string get_redirect_url() {
    // Docs: https://github.com/ikod/dlang-requests
    import requests;

    auto url_sign = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/jwssignverifyapi/sign";

    auto jj_sign = parseJSON(`{
        "debtor": {
            "bankId": "BCYPCY2N",
            "accountId": "351012345671"
        },
        "creditor": {
            "bankId": "BCYPCY2N",
            "accountId": "48193222324233",
            "utilityCompany": "21",
            "billNumber": "123456",
            "checkDigit": "8",
            "amountCheckDigit": "8"
        },
        "transactionAmount": {
            "amount": 123,
            "currency": "EUR"
        },
        "paymentDetails": "Utility Bill"
    }`);

    auto url_init_token = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/oauth2/token";

    string client_id = "4dc07264f9bd6b360eedbe6fb0f4e1a0";
    string client_secret = "30bb95a1582d9d3af8a80a61680d8045";

    auto payload_init_token = "client_id="~client_id~"&client_secret="~client_secret~"&grant_type=client_credentials&scope=TPPOAuth2Security";
    string[string] headers_init_token;
    headers_init_token["Content-Type"] = "application/x-www-form-urlencoded";

    Request rq_init_token = Request();

    rq_init_token.addHeaders(headers_init_token);
    auto response_init_token = rq_init_token.post(url_init_token, payload_init_token);

    string init_token = parseJSON(to!string(response_init_token.responseBody))["access_token"].toString[1..$-1];

    auto payload_sign = toJSON(jj_sign);

    string[string] headers_sign;
    headers_sign["Content-Type"] = "application/json";
    headers_sign["tppId"] = "singpaymentdata";

    Request rq_sign = Request();

    rq_sign.addHeaders(headers_sign);
    auto response_sign = rq_sign.post(url_sign, payload_sign);

    auto url_init_payment = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/v1/payments/initiate";

    auto payload_init_payment = response_sign.responseBody.toString;
    writeln(payload_init_payment);

    string[string] headers_init_payment;
    headers_init_payment["Content-Type"] = "application/json";
    headers_init_payment["Authorization"] = "Bearer " ~ init_token;
    headers_init_payment["journeyId"] = "757af639-35a5-46c9-8d87-b33f0597fde4";
    headers_init_payment["timeStamp"] =  "1729361953";
    headers_init_payment["lang"] = "en";
    headers_init_payment["loginTimeStamp"] = "1729361953";
    headers_init_payment["customerDevice"] = "56f8d82b-ae99-4313-9658-8ea8b104a0e0";
    headers_init_payment["customerIp"] = "1.1.1.1";
    headers_init_payment["customerSessionId"] = "d487af13-6df9-4f93-9487-90b0c1e46e93";

    Request rq_init_payment = Request();

    rq_init_payment.addHeaders(headers_init_payment);
    auto response_init_payment = rq_init_payment.post(url_init_payment, payload_init_payment);

    string payment_id = parseJSON(to!string(response_init_payment.responseBody))["payment"]["paymentId"].toString[1..$-1];

    string redirect_url = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/oauth2/authorize?response_type=code&redirect_uri=http://"~ip_add~":8080/redir&scope=UserOAuth2Security&client_id="~client_id~"&paymentid="~payment_id;
    return redirect_url;
}

void assistant_logic(Request r, Output o) {
    o.serveFile("static/index.html");
}

void redirection_logic(Request r, Output o) {
    o.addHeader("location", get_redirect_url()); 
    o.status = 302;
}

void finalize_payment(Request r, Output o) {
    import mustache;
    import std.file : write;

    auto code = r.get.read("code");
    //writeln(code);
    // executing the payment
    //url = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/v1/payments/9f838168-77ca-470a-9114-754f94d19ce0/execute"

    //payload = json.dumps({})
    //headers = {
    //  'Content-Type': 'application/json',
    //  'Authorization': 'Bearer AAPsOAIwqHDoSD6IDKXQUMhX9fV00-r8d9ZURuBc42QAqE2jdDvJMLC24n8pEuLwbVJFmp3eATOiDpKDVRSHYSwiV9w0N1L0E633B-xH2rI7ew',
    //  'journeyId': '7d9b5088-4577-4ace-a1a4-1e4aa1fce906',
    //  'timeStamp': '1729371138',
    //  'Cookie': 'TS013b36ab=0179594e112e94453453ecead05ab071ac1ef69a9bd61b8bdcfd8159cb4b2254b8a8242dc98d0dde932bed8d81df3f9f90e9c12776f4666b41541b7edfeb859c411abfd2f8; de2a657d1673ca26a0e0abed5da67a83=c5a7b127c02a76d77fdf4912ee5581c6'
    //}

    //response = requests.request("POST", url, headers=headers, data=payload)
    // getting payment status/receipt

    // render the page
    alias Mustache = MustacheEngine!(string);

    Mustache must;
    auto context = new Mustache.Context;
    context["payment_amount"]  = 123;
    "static/final_payment.html".write(must.render("static/final_payment", context));
    // serve the page
    o.serveFile("static/final_payment.html");
}

@endpoint
@route!(x => x.path.startsWith("/images/")) 	// ... in the images folder
void static_serve(Request req, Output output)
{
	output.serveFile("static" ~ req.path);
}
@endpoint
@route!(x => x.path.endsWith("css")) 	// ... in the images folder
void css(Request req, Output output)
{
	output.serveFile("static" ~ req.path);
}
@route!"/"
@endpoint void home(Request r, Output o) { gen_new_code(); o.serveFile("static/home.html"); }
@route!"/assistant"
@endpoint void index(Request r, Output o) { assistant_logic(r, o); }
@route!"/payment"
@endpoint void payment(Request r, Output o) { redirection_logic(r, o); }
@route!"/redir"
@endpoint void redir(Request r, Output o) { finalize_payment(r, o); }