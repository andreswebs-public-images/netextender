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

`ALWAYS_TRUST` and `AUTO_RECONNECT` are optional; unset them to disable.

## Authors

**Andre Silva** - [@andreswebs](https://github.com/andreswebs)

## License

This project is licensed under the [Unlicense](UNLICENSE).
