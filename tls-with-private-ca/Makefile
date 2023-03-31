.SUFFIXES: .csr .pem .conf
.PRECIOUS: root-ca-key.pem root-ca-cert.pem 
.PRECIOUS: %-int-ca/int-ca-key.pem %-int-ca/int-ca-cert.pem %-int-ca/int-ca-cert-chain.pem %-int-ca/int-ca.csr %-int-ca/intermediate.conf
.PRECIOUS: ${INT_CA}/client-server/%/key.pem ${INT_CA}/client-server/%/cert.pem ${INT_CA}/client-server/%/cert-chain.pem ${INT_CA}/client-server/%/client-server.csr ${INT_CA}/client-server/%/client-server.conf 
.SECONDARY: root-ca.conf

.DEFAULT_GOAL := help

SELF_DIR := $(dir $(lastword $(MAKEFILE_LIST)))

include $(SELF_DIR)common.mk



# ------------------------------------------------------------------------
# help: print this help message
# ------------------------------------------------------------------------

.PHONY: help

help:
	@fgrep -h "##" $(MAKEFILE_LIST) | fgrep -v fgrep | sed -e 's/##//'



# ------------------------------------------------------------------------
# root-ca: generate root CA files (key and certificate) in current 
#          directory.
# ------------------------------------------------------------------------

.PHONY: root-ca

root-ca: root-ca-key.pem root-ca-cert.pem

root-ca-cert.pem: root-ca-key.pem root-ca.conf
	@echo "generating $@"
	@openssl req -config root-ca.conf -key root-ca-key.pem -new -x509 -days 7300 -sha256 -extensions req_ext -out $@

root-ca-key.pem:
	@echo "generating $@"
	@openssl genrsa -out $@ 4096



# ------------------------------------------------------------------------
# <name>-int-ca: generate self signed intermediate certificates for <name> 
#                and store them under <name> directory.
# ------------------------------------------------------------------------

.PHONY: %-int-ca

%-int-ca: %-int-ca/int-ca-cert-chain.pem
	@echo "done"

%-int-ca/int-ca-cert-chain.pem: %-int-ca/int-ca-cert.pem root-ca-cert.pem
	@echo "generating $@"
	@cat $^ > $@
	@echo "Intermediate inputs stored in $(dir $<)"

%-int-ca/int-ca-cert.pem: %-int-ca/int-ca.csr root-ca-key.pem root-ca-cert.pem
	@echo "generating $@"
	@openssl x509 -req -sha256 -days $(INTCA_DAYS) \
		-CA root-ca-cert.pem -CAkey root-ca-key.pem -CAcreateserial\
		-extensions x509_ext -extfile $(dir $<)/intermediate.conf \
		-in $< -out $@

%-int-ca/int-ca.csr: L=$(dir $@)
%-int-ca/int-ca.csr: %-int-ca/int-ca-key.pem %-int-ca/intermediate.conf
	@cat $(L)/intermediate.conf
	@echo "generating $@"
	@openssl req -sha256 -new -config $(L)/intermediate.conf -key $< -out $@

%-int-ca/int-ca-key.pem:
	@echo "generating $@"
	@mkdir -p $(dir $@)
	@mkdir -p $(dir $@)/client-server
	@openssl genrsa -out $@ 4096



# ------------------------------------------------------------------------
# <name>-certs: generate self signed intermediate certificates for <name> 
#               and store them under <name> directory.
# ------------------------------------------------------------------------

.PHONY: %-cert

%-cert: ${INT_CA}/client-server/%/cert-chain.pem
	@echo "done"

${INT_CA}/client-server/%/cert-chain.pem: ${INT_CA}/client-server/%/cert.pem ${INT_CA}/int-ca-cert.pem root-ca-cert.pem
	@echo "generating $@"
	@cat $^ > $@
	@echo "client-server certs stored in $(dir $<)"

${INT_CA}/client-server/%/cert.pem: ${INT_CA}/client-server/%/client-server.csr
	@echo "generating $@"
	@openssl x509 -sha256 -req -days $(CS_DAYS) \
		-CA $(dir $<)../../int-ca-cert.pem  -CAkey $(dir $<)../../int-ca-key.pem -CAcreateserial\
		-extensions req_ext -extfile $(dir $<)/client-server.conf \
		-in $< -out $@

${INT_CA}/client-server/%/client-server.csr: L=$(dir $@)

${INT_CA}/client-server/%/client-server.csr: ${INT_CA}/client-server/%/key.pem ${INT_CA}/client-server/%/client-server.conf
	@echo "generating $@"
	@openssl req -sha256 -new -config $(L)/client-server.conf -key $< -out $@

${INT_CA}/client-server/%/key.pem: check-for-intermediate-ca
	@echo $*
	@echo "generating $@"
	@mkdir -p $(dir $@)
	@openssl genrsa -out $@ 4096

check-for-variables:
ifndef INT_CA
	$(error Error: INT_CA is undefined)
endif

ifndef SANS
	@echo "No SANS defined, but that's ok"
endif

check-for-intermediate-ca: check-for-variables ${INT_CA}
	@echo "Intermediate CA ${INT_CA} found, let's go"