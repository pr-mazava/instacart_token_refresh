import requests
import json
import os
from datetime import datetime
from dotenv import load_dotenv

load_dotenv()


def get_client_list():
    clients = os.getenv("CLIENTS", "")
    return [c.strip().upper() for c in clients.split(",") if c.strip()]


def get_client_var(client, var):
    return os.getenv(f"{client}_{var}")


def main():
    url = "https://api.ads.instacart.com/oauth/token"
    headers = {"Content-Type": "application/json"}

    clients = get_client_list()
    if not clients:
        print("No CLIENTS found in .env. Please set CLIENTS=FLAGSTONE,SCHREIBER,...")
        return

    for client in clients:
        print(f"\n==== {client} ====")
        client_id = get_client_var(client, "CLIENT_ID")
        client_secret = get_client_var(client, "CLIENT_SECRET")
        redirect_uri = get_client_var(client, "REDIRECT_URI")
        auth_code = get_client_var(client, "AUTH_CODE")

        if not client_id:
            client_id = input(f"{client} Client ID: ").strip()
        if not client_secret:
            client_secret = input(f"{client} Client Secret: ").strip()
        if not redirect_uri:
            redirect_uri = input(f"{client} Redirect URI: ").strip()
        if not auth_code:
            auth_code = input(f"{client} Auth Code: ").strip()

        data = {
            "client_id": client_id,
            "client_secret": client_secret,
            "redirect_uri": redirect_uri,
            "code": auth_code,
            "grant_type": "authorization_code",
        }

        print(f"\nRequesting token for {client}...")
        response = requests.post(url, headers=headers, data=json.dumps(data))

        try:
            resp_json = response.json()
        except Exception:
            print("Error: Could not decode JSON from response:")
            print(response.text)
            continue

        now = datetime.now().strftime("%Y%m%d_%H%M")
        out_name = f"{client.lower()}_refresh_token_{now}.json"
        with open(out_name, "w") as outfile:
            json.dump(resp_json, outfile, indent=2)
        print(f"\nResult for {client} written to: {out_name}")

        if "refresh_token" in resp_json:
            txt_name = f"{client.lower()}_refresh_token_{now}.txt"
            with open(txt_name, "w") as txtfile:
                txtfile.write(resp_json["refresh_token"])
            print(f"Refresh token for {client} saved to: {txt_name}")

        if response.status_code == 200 and "refresh_token" in resp_json:
            print(f"\n{client} Success! Refresh token (also saved to file):")
            print(json.dumps(resp_json, indent=2))
        else:
            print(
                f"\n{client} Error {response.status_code} from Instacart API (saved to file):"
            )
            print(json.dumps(resp_json, indent=2))


if __name__ == "__main__":
    main()
