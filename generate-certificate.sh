#!/usr/bin/env bash

rm -f certificate.conf certificate.crt certificate.key certificate.p12 certificate.pem key.pem
short=`hostname -s`
full=`hostname -f`
ip=`hostname -I | cut -f1 -d' '`
cat > certificate.conf << EOF
default_bits = 1024
distinguished_name = req_distinguished_name
req_extensions = req_ext
x509_extensions = v3_req
prompt = no
[req_distinguished_name]
countryName = US
stateOrProvinceName = AZ
localityName = Phoenix
organizationName = Self-signed certificate
commonName = $short
[req_ext]
subjectAltName = @alt_names
[v3_req]
subjectAltName = @alt_names
[alt_names]
IP.1 = $ip
DNS.1 = $full
EOF
openssl req -x509 -newkey rsa:1024 -days 3650 -nodes -keyout certificate.key -out certificate.crt -config certificate.conf
openssl pkcs12 -export -in certificate.crt -inkey certificate.key -out certificate.p12 -passout pass:changeit -name $full
ln -s certificate.key key.pem
ln -s certificate.crt certificate.pem
chmod a+r *