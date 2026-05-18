# netextender

Containerized NetExtender.

## Official Docs

- [SonicWall KB: How can I download and install NetExtender on Linux?](https://www.sonicwall.com/support/knowledge-base/how-can-i-download-and-install-netextender-on-linux/180105195559153/)
- [SonicWall: Launching the NetExtender CLI for Linux](https://www.sonicwall.com/support/technical-documentation/docs/netextender-feature_guide/Content/NetExtender-CLI-Interface/netextender-cli-linux.htm)
- [SonicWall: Using the NetExtender Command Line Interface](https://www.sonicwall.com/support/technical-documentation/docs/netextender-feature_guide/Content/Using-NetExtender/using-the-netextender-cli.htm/)
- [SonicWall: NetExtender Feature Guide](https://www.sonicwall.com/support/technical-documentation/docs/netextender-feature_guide/Content/NetExtender-CLI-Interface/using-the-netextender-cli.htm)

## Run

The container needs `CAP_NET_ADMIN` to configure the tunnel interface and routes, and access to `/dev/net/tun` from the host.

```sh
export VPN_USERNAME="user@example.com"
export VPN_PASSWORD="your-password"
export VPN_DOMAIN="LocalDomain"
export VPN_SERVER="vpn.example.com:4433"
```

```sh
docker run \
    --rm \
    --interactive \
    --name netextender \
    --cap-add=NET_ADMIN \
    --device=/dev/net/tun \
    --env VPN_USERNAME="${VPN_USERNAME}" \
    --env VPN_PASSWORD="${VPN_PASSWORD}" \
    --env VPN_DOMAIN="${VPN_DOMAIN}" \
    --env VPN_SERVER="${VPN_SERVER}" \
    andreswebs/netextender
```

## Compose with SOCKS5 proxy

The tunnel lives inside the container's network namespace, so the VPN is only usable from processes that share that namespace. The bundled [compose.yaml](compose.yaml) wires up two services:

- `netextender` — the VPN client (this image)
- `socks` — a [SOCKS5 server](https://hub.docker.com/r/serjs/go-socks5-proxy) running in `network_mode: service:netextender`, sharing the VPN's network stack

The SOCKS5 server's port (`1080`) is published on the `netextender` container and bound to `127.0.0.1` on the host, so anything on your machine can reach VPN-side resources by routing through `127.0.0.1:1080`. `depends_on` with `condition: service_healthy` makes the proxy wait until the VPN tunnel is actually up.

Bring it up:

```sh
export VPN_USERNAME="user@example.com"
export VPN_PASSWORD="your-password"
export VPN_DOMAIN="LocalDomain"
export VPN_SERVER="vpn.example.com:4433"
```

```sh
docker compose up --detach
docker compose ps
```

### SSH through the proxy

Use `ncat` (from `nmap`) as the SOCKS5 client — its `--proxy-type socks5` flag works identically on macOS and Linux:

```sh
brew install nmap   # or `apt install ncat`
```

Then in `~/.ssh/config`:

```sshconfig
# Example - assuming the 192.168.102.* is in your VPN:
Host 192.168.102.*
    User your-username
    ProxyCommand ncat --proxy 127.0.0.1:1080 --proxy-type socks5 %h %p
    StrictHostKeyChecking accept-new
    UserKnownHostsFile ~/.ssh/known_hosts_vpn
```

Now `ssh your-username@192.168.102.9` will tunnel through the containerized VPN.

For other tools, point them at `socks5://127.0.0.1:1080`. Examples:

```sh
curl --socks5 127.0.0.1:1080 http://internal.example.com/
git -c http.proxy=socks5://127.0.0.1:1080 clone ...
```

## Authors

**Andre Silva** - [@andreswebs](https://github.com/andreswebs)

## License

This project is licensed under the [Unlicense](UNLICENSE).
