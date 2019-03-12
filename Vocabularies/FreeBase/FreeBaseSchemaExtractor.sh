#!/bin/sh
# Unix command used to extract the Schema from the data dumps downloadable from https://developers.google.com/freebase/
zgrep -Ev "<http://rdf.freebase.com/ns/g\..*>|<http://rdf.freebase.com/ns/m\..*>" freebase-rdf-latest.gz | gzip > FreeBaseInstanceFree.nt.gz


