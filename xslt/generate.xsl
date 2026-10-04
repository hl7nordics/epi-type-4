<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fhir="http://hl7.org/fhir"
  exclude-result-prefixes="xs">

  <xsl:output method="xml" indent="yes" encoding="UTF-8"/>

  <xsl:mode on-no-match="shallow-copy"/>

  <xsl:variable name="now" select="format-dateTime(adjust-dateTime-to-timezone(current-dateTime(), xs:dayTimeDuration('PT0S')), '[Y0001]-[M01]-[D01]T[H01]:[m01]:[s01]Z')"/>

  <xsl:include href="generate/bundle.xsl"/>
  <xsl:include href="generate/composition.xsl"/>

</xsl:stylesheet>
