import std.stdio;
import std.conv;
import requests;

void main()
{
    import std.json;
/*
    auto url_1 = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/oauth2/token";

    string client_id = "4dc07264f9bd6b360eedbe6fb0f4e1a0";
    string client_secret = "30bb95a1582d9d3af8a80a61680d8045";

    auto payload_1 = "client_id="~client_id~"&client_secret="~client_secret~"&grant_type=client_credentials&scope=TPPOAuth2Security";
    string[string] headers_1;
    headers_1["Content-Type"] = "application/x-www-form-urlencoded";
    headers_1["Cookie"] = "TS013b36ab=0179594e11b638a2e39b97c9776f6ea969c89552afc65aad283c82419b28024b8e5476740400009650466ea66e1892d6a4c1b3630d4db3787cc40bd2a0e4e7f118f3b8f030; de2a657d1673ca26a0e0abed5da67a83=c5a7b127c02a76d77fdf4912ee5581c6";

    Request rq_1 = Request();

    rq_1.addHeaders(headers_1);
    auto response_1 = rq_1.post(url_1, payload_1);

    writeln(response_1.responseBody);

    auto url_2 = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/v1/subscriptions";

    auto jj = parseJSON(`{
    "accounts": {
        "transactionHistory": True,
        "balance": True,
        "details": True,
        "checkFundsAvailability": True
    },
    "payments": {
        "limit": 99999999,
        "currency": "EUR",
        "amount": 999999999
    }
    }`);
    auto payload_2 = toJSON(jj);
     
    string token_auth_1 = parseJSON(to!string(response_1.responseBody))["access_token"].toString;

    string[string] headers_2;
    headers_2["Authorization"]= "Bearer "~token_auth_1[1..$-1];
    headers_2["Content-Type"]= "application/json";
    headers_2["timeStamp"]= "1729352087";
    headers_2["journeyId"]= "15e4263f-787e-4646-a206-f8d6950e19e0";

    Request rq_2 = Request();

    rq_2.addHeaders(headers_2);
    auto response_2 = rq_2.post(url_2, payload_2);

    string subscr_id = to!string(parseJSON(to!string(response_2.responseBody))["subscription_id"]);

    writeln(subscr_id);

    auto url_3 = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/oauth2/authorize?response_type=code&redirect_uri={{yourAppRedirectionURL}}&scope=UserOAuth2Security&client_id={{yourClientId}}&subscriptionid={{subscriptionId}}";
    */

    auto url_sign = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/jwssignverifyapi/sign";

    auto jj_sign = parseJSON(`{
    "debtor": {
        "bankId": "",
        "accountId": "351012345671"
    },
    "creditor": {
        "bankId": "CITIUS33",
        "accountId": "48193222324233"
    },
    "transactionAmount": {
        "amount": 30,
        "currency": "EUR"
    },
    "paymentDetails": "SWIFT Transfer"
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

    //writeln(response_sign.responseBody);

    auto url_init_payment = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/v1/payments/initiate";

    auto jj_payment = parseJSON(`{
    "payload": "eyAiZGVidG9yIjp7ICJiYW5rSWQiOiIiLCAiYWNjb3VudElkIjoiMzUxMDEyMzQ1NjcxIiB9LCAiY3JlZGl0b3IiOnsgImJhbmtJZCI6IkNJVElVUzMzIiwgImFjY291bnRJZCI6IjQ4MTkzMjIyMzI0MjMzIiB9LCAidHJhbnNhY3Rpb25BbW91bnQiOnsgImFtb3VudCI6MzAsICJjdXJyZW5jeSI6IkVVUiIgfSwgInBheW1lbnREZXRhaWxzIjoiU1dJRlQgVHJhbnNmZXIiIH0",
    "signatures": [
        {
        "protected": "eyJhbGciOiJSUzI1NiJ9",
        "signature": "s9vy53hGobNDeuQGyQI1J4-Kopo7AsVPMNYuyku9PLV2UXSAzkEfPQQPHYsAHe4ZnArv06XDp2Qsnqti5v88IWIDQe1AlVmNLEiVmkIBwXjsSWcRaNqVPWVas70SuO6ddrqH1Vz_UbvBJD02e49iDhuuCnsKZYBU7jvo4o-JvHyWXneXFElQvXKSCA-iddaivXdKWEuv7R2pkDr3xOJKJ4xS8Ugt5vKUVWMVQhDK6fOfzh50VeCSxC0v-XByMC4wLZcb4HbPtH9YEtP0MqF_AkqFRGD8v5OBBYr6pQdQ7oBRe1N6a9UkAhG0UDrfZFPoD6m1Gbdd9__RspWOU7fMDA"
        }
    ]
    }`);
    auto payload_init_payment = toJSON(jj_payment);

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

    //writeln(to!string(response_init_payment.responseBody));
    string payment_id = parseJSON(to!string(response_init_payment.responseBody))["payment"]["paymentId"].toString[1..$-1];
    writeln(payment_id);

    string redirect_url = "https://sandbox-apis.bankofcyprus.com/df-boc-org-sb/sb/psd2/oauth2/authorize?response_type=code&redirect_uri=http://10.1.1.49:8080/redir&scope=UserOAuth2Security&client_id="~client_id~"&paymentid="~payment_id;
    writeln(redirect_url);
}
