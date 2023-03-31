# Usage

## Default values

Default values for the root CA, intermediate CA and server certificates can be found in `common.mk`. This file can be modified if certificate details need to be more specific.

## Create a Root CA

`make root-ca`

The Root CA files will be placed in the root folder.

## Create an Intermediate CA

`make <int-ca-name>-int-ca`

The Intermediate CA files will be placed in the `<int-ca-name>-int-ca` folder.

## Create Server Certificates

`make <server-name>-cert INT_CA=<int-ca-name>-int-ca SANS="<space delimited list of SANs (e.g. konghq.com *.konghq.com)>"`

Make sure to use double quotes around the SANs list

The server certificates will be placed in the `<int-ca-name>-int-ca/<server-name>` folder.
