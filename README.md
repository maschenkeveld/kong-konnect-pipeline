# Kong Cloud CLI
CLI tool for easy operation and automation of a Kong Cloud (Konnect) organisation.

## Build the Tool

You can construct the tool locally if you have Go installed:

```sh
CGO_ENABLED=0 go build -o kongcloud
```

Or you can build it using a Docker image:

```sh
docker run -dt --rm -v $(pwd):/host --workdir /host --name kongcloud-builder golang:1.17-alpine
sleep 3
docker exec -it kongcloud-builder ash -c "CGO_ENABLED=0 GOOS=darwin GOARCH=amd64 go build -o kongcloud"
docker kill kongcloud-builder
```

Swap the GOOS and GOARCH flags to match the system you are running on; this example is for INTEL Apple computers.

## Install the Tool

Just put the output binary `./kongcloud` into some PATH, like `/usr/local/bin/kongcloud`

## Authentication

For authenticating with Konnect, the exact same global flags apply - see the Deck documentation here: https://docs.konghq.com/deck/latest/reference/deck/

Any starting `--konnect-*` will also apply in the same way to this tool, for example:

```sh
$ kongcloud --konnect-token-file=/Users/me/.password/konnect-token --konnect-addr="https://eu.api.konghq.com/" ... ... ...
```

will create you a client that uses your PAT stored in ~/.password/konnect-token, and will authenticate and use the EU Konnect endpoints (creating and managing EU resources only!)

## Usage

There are many commands in this tool, and more will be added. For now, the most important:

### Printing All Runtimegroup / Service / Route Information

To print details of ALL runtime groups, their services, and their service's routes, to the console in CSV format (for Excel import), use the `runtimegroups describe --all` command.

Firstly **make absolutely certain that the PAT token in use has role "Organization Admin Readonly" and NOTHING ELSE!**

After getting this PAT token, execute a command like this:

```sh
$ kongcloud --konnect-token-file=/Users/me/.password/konnect-readonly-token --konnect-addr="https://eu.api.konghq.com" runtimegroups describe --all > output.csv
```

This will print you out an Excel-compatible CSV, of ALL services and routes created in ALL runtime groups.

It will **not** print certificates/keys, plugin configuration, or vaults, and thus is safe for internal auditing purposes.

### Create a Runtime Group

To create a new runtime group, first decide the correct URL endpoint for the target Konnect region:

* **EU** -> https://eu.api.konghq.com
* **US** -> https://us.api.konghq.com

This becomes your "--kong-addr" flag.

Make sure you have a Konnect access token (either in text, or in a file on disk somewhere).

**Now execute the command to create the Runtime Group:**

```sh
$ kongcloud --konnect-token-file=/Users/me/.password/konnect-token --konnect-addr="https://eu.api.konghq.com/" runtimegroups add --name "rg-name-here" --desc "Description here"

{
  "id": "aaaaaaaa-bbbb-cccc-dddd-ffffffffffff",
  "name": "rg-name-here",
  "description": "Description Here",
  "metadata": {
    "labels": {}
  },
  "config": {
    "cp_outlet": "https://ffffffffff.eu.cp0.konghq.com/",
    "telemetry_endpoint": "https://ffffffffff.eu.tp0.konghq.com/",
    "dns_prefix": "ffffffffff"
  },
  "created_at": "2022-08-30T12:14:08.537Z",
  "updated_at": "2022-08-30T12:14:08.537Z"
}
```

### Uploading

Now you can upload your "runtime instances" certificate to the new group:

```sh
$ kongcloud --konnect-token-file=/Users/jack.tysoe/.password/konnect-token --konnect-addr="https://eu.api.konghq.com/" runtimegroups add-cluster-certificate --cert-path=/tmp/cluster.crt --runtime-group-id="aaaaaaaa-bbbb-cccc-dddd-ffffffffffff" --runtime-group-name="rg-name-here"

{
  "id": "aaaaaaaa-bbbb-cccc-dddd-ffffffffffff",
  "name": "rg-name-here",
  "description": "Description Here",
  "metadata": {
    "labels": {}
  },
  "config": {
    "cp_outlet": "https://ffffffffff.eu.cp0.konghq.com/",
    "telemetry_endpoint": "https://ffffffffff.eu.tp0.konghq.com/",
    "dns_prefix": "ffffffffff"
  },
  "created_at": "2022-08-30T12:14:08.537Z",
  "updated_at": "2022-08-30T12:14:08.537Z"
}
```

The output is the same as the "create runtime group", however your certificate should now be attached! Now you can launch a runtime group data plane:

```sh
export CP_SERVER_NAME=ffffffffff.eu.cp0.konghq.com
export TP_SERVER_NAME=ffffffffff.eu.tp0.konghq.com
docker run -it --rm \
        -e "KONG_ROLE=data_plane" \
        -e "KONG_DATABASE=off" \
        -e "KONG_ANONYMOUS_REPORTS=off" \
        -e "KONG_VITALS_TTL_DAYS=723" \
        -e "KONG_CLUSTER_MTLS=pki" \
        -e "KONG_CLUSTER_CONTROL_PLANE=$CP_SERVER_NAME:443" \
        -e "KONG_CLUSTER_SERVER_NAME=$CP_SERVER_NAME" \
        -e "KONG_CLUSTER_TELEMETRY_ENDPOINT=$TP_SERVER_NAME:443" \
        -e "KONG_CLUSTER_TELEMETRY_SERVER_NAME=$TP_SERVER_NAME" \
        -e "KONG_CLUSTER_CERT=/config/cluster.crt" \
        -e "KONG_CLUSTER_CERT_KEY=/config/cluster.key" \
        -e "KONG_LUA_SSL_TRUSTED_CERTIFICATE=system,/config/cluster.crt" \
        --mount type=bind,source="$(pwd)",target=/config,readonly \
        -p 8000:8000 \
        -p 8443:8443 \
        kong/kong-gateway:2.8.1.4-alpine
```
