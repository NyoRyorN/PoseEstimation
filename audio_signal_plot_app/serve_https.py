#!/usr/bin/env python3
import argparse
import http.server
import ssl


def main():
    parser = argparse.ArgumentParser(description="Serve Audio Scope over HTTPS.")
    parser.add_argument("--host", default="0.0.0.0")
    parser.add_argument("--port", default=5174, type=int)
    parser.add_argument("--cert", default="localhost-cert.pem")
    parser.add_argument("--key", default="localhost-key.pem")
    args = parser.parse_args()

    server = http.server.ThreadingHTTPServer(
        (args.host, args.port),
        http.server.SimpleHTTPRequestHandler,
    )
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.load_cert_chain(certfile=args.cert, keyfile=args.key)
    server.socket = context.wrap_socket(server.socket, server_side=True)

    print(f"Serving HTTPS on {args.host}:{args.port}")
    server.serve_forever()


if __name__ == "__main__":
    main()
