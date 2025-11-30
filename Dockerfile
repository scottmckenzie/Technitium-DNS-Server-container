# build stage
FROM mcr.microsoft.com/dotnet/sdk:10.0-noble AS build


# Build the TechnitiumLibrary source
RUN git clone --depth 1 --branch "dns-server-${VERSION}" https://github.com/TechnitiumSoftware/TechnitiumLibrary.git .
RUN <<EOF
  dotnet build TechnitiumLibrary/TechnitiumLibrary.ByteTree/TechnitiumLibrary.ByteTree.csproj -c Release
  dotnet build TechnitiumLibrary/TechnitiumLibrary.Net/TechnitiumLibrary.Net.csproj -c Release
  dotnet build TechnitiumLibrary/TechnitiumLibrary.Security.OTP/TechnitiumLibrary.Security.OTP.csproj -c Release
EOF

# Build the DnsServer source
RUN git clone --depth 1 --branch ${VERSION} https://github.com/TechnitiumSoftware/DnsServer.git .
RUN dotnet publish DnsServer/DnsServerApp/DnsServerApp.csproj -c Release

# final stage/image
FROM mcr.microsoft.com/dotnet/runtime-deps:10.0-noble-chiseled

WORKDIR /opt/technitium/dns
COPY --from=build --link ./DnsServerApp/bin/Release/publish /opt/technitium/dns

# Support for graceful shutdown:
STOPSIGNAL SIGINT

ENTRYPOINT ["dotnet", "/opt/technitium/dns/DnsServerApp.dll"]
CMD ["/etc/dns"]

EXPOSE \
  # Standard DNS service
  53/udp 53/tcp      \
  # DNS-over-QUIC (UDP) + DNS-over-TLS (TCP)
  853/udp 853/tcp    \
  # DNS-over-HTTPS (UDP => HTTP/3) (TCP => HTTP/1.1 + HTTP/2)
  443/udp 443/tcp    \
  # DNS-over-HTTP (for when running behind a reverse-proxy that terminates TLS)
  80/tcp 8053/tcp    \
  # Technitium web console + API (HTTP / HTTPS)
  5380/tcp 53443/tcp \
  # DHCP
  67/udp
