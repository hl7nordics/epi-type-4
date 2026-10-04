<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fhir="http://hl7.org/fhir"
  xmlns:html="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs fhir html">

  <xsl:template match="html:*">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <xsl:variable name="fhirBundle" select="/fhir:Bundle"/>
      <xsl:variable name="cssClasses" select="tokenize(@class, '\s+')"/>
      <xsl:for-each select="$cssClasses">
        <xsl:variable name="cssClassName" select="."/>
        <xsl:if test="starts-with($cssClassName, 'id-ref-')">
          <xsl:variable name="resourceId" select="substring-after($cssClassName, 'id-ref-')"/>
          <xsl:variable name="resourceElement" select="$fhirBundle/fhir:entry/fhir:resource/fhir:*[fhir:id/@value = $resourceId]"/>
          <xsl:apply-templates select="$resourceElement" mode="resourceReference"/>
        </xsl:if>
      </xsl:for-each>
      <xsl:apply-templates select="node()"/>
    </xsl:copy>
  </xsl:template>

  <!-- This mode processes the structured data element and creates data attributes from codes in the resource -->
  <xsl:template match="fhir:ClinicalUseDefinition" mode="resourceReference">
    <xsl:if test="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept">
      <xsl:attribute name="data-element-type">coded-value</xsl:attribute>
      <xsl:attribute name="data-code-system">
        <xsl:value-of select="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:coding[1]/fhir:system/@value"/>
      </xsl:attribute>
      <xsl:attribute name="data-code">
        <xsl:value-of select="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:coding[1]/fhir:code/@value"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

</xsl:stylesheet>
