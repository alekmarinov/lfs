#!/bin/bash
set -e
echo "Building BLFS-docbook-xml.."
echo "Approximate build time: 0.1 SBU"
echo "Required disk space: 1.2 MB"

# 49. docbook-xml
# The DocBook-4.5 XML DTD-4.5 package contains document type definitions for
# verification of XML data files against the DocBook rule set.
# required: libxml2,sgml-common,unzip
# https://www.linuxfromscratch.org/blfs/view/stable/pst/docbook.html

VER=$(ls /sources/docbook-xml-*.zip | sed 's/[^0-9]*//' | sed 's/[^0-9]*$//')
mkdir /tmp/docbook \
    && unzip /sources/docbook-xml-*.zip -d /tmp/docbook \
    && pushd /tmp/docbook \
    && install -v -d -m755 /usr/share/xml/docbook/xml-dtd-$VER \
    && install -v -d -m755 /etc/xml \
    && chown -R root:root . \
    && cp -v -af docbook.cat *.dtd ent/ *.mod \
        /usr/share/xml/docbook/xml-dtd-$VER

if [ ! -e /etc/xml/docbook ]; then \
    xmlcatalog --noout --create /etc/xml/docbook;
fi \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//DTD DocBook XML V4.5//EN" \
        "http://www.oasis-open.org/docbook/xml/4.5/docbookx.dtd" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//DTD DocBook XML CALS Table Model V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/calstblx.dtd" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//DTD XML Exchange Table Model 19990315//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/soextblx.dtd" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ELEMENTS DocBook XML Information Pool V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/dbpoolx.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ELEMENTS DocBook XML Document Hierarchy V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/dbhierx.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ELEMENTS DocBook XML HTML Tables V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/htmltblx.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ENTITIES DocBook XML Notations V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/dbnotnx.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ENTITIES DocBook XML Character Entities V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/dbcentx.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "public" \
        "-//OASIS//ENTITIES DocBook XML Additional General Entities V4.5//EN" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5/dbgenent.mod" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "rewriteSystem" \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        /etc/xml/docbook \
    && xmlcatalog --noout --add "rewriteURI" \
        "http://www.oasis-open.org/docbook/xml/4.5" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        /etc/xml/docbook

if [ ! -e /etc/xml/catalog ]; then
    xmlcatalog --noout --create /etc/xml/catalog
fi \
    && xmlcatalog --noout --add "delegatePublic" \
        "-//OASIS//ENTITIES DocBook XML" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog \
    && xmlcatalog --noout --add "delegatePublic" \
        "-//OASIS//DTD DocBook XML" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog \
    && xmlcatalog --noout --add "delegateSystem" \
        "http://www.oasis-open.org/docbook/" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog \
    && xmlcatalog --noout --add "delegateURI" \
        "http://www.oasis-open.org/docbook/" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog
    
for DTDVERSION in 4.1.2 4.2 4.3 4.4
do
    xmlcatalog --noout --add "public" \
        "-//OASIS//DTD DocBook XML V$DTDVERSION//EN" \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION/docbookx.dtd" \
        /etc/xml/docbook
    xmlcatalog --noout --add "rewriteSystem" \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        /etc/xml/docbook
    xmlcatalog --noout --add "rewriteURI" \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION" \
        "file:///usr/share/xml/docbook/xml-dtd-4.5" \
        /etc/xml/docbook
    xmlcatalog --noout --add "delegateSystem" \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog
    xmlcatalog --noout --add "delegateURI" \
        "http://www.oasis-open.org/docbook/xml/$DTDVERSION/" \
        "file:///etc/xml/docbook" \
        /etc/xml/catalog
done

popd \
    && rm -rf /tmp/docbook
