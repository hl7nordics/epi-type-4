<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="3.0"
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:xs="http://www.w3.org/2001/XMLSchema"
  xmlns:fhir="http://hl7.org/fhir"
  xmlns:html="http://www.w3.org/1999/xhtml"
  exclude-result-prefixes="xs fhir html">

  <xsl:template match="html:div[@id = 'undesirable-effects-table']">
    <div xmlns="http://www.w3.org/1999/xhtml" class="generated-text" id="undesirable-effects-table">
      <xsl:call-template name="side-effect-table"/>
    </div>
  </xsl:template>

  <xsl:template name="side-effect-table">
    <xsl:variable name="resources" select="/fhir:Bundle/fhir:entry/fhir:resource[fhir:ClinicalUseDefinition[fhir:type/@value = 'undesirable-effect']]"/>
    <table xmlns="http://www.w3.org/1999/xhtml" class="table">
      <thead>
        <tr>
          <th>System Order Class</th>
          <th>Frequency</th>
          <th>Adverse reaction</th>
        </tr>
      </thead>
      <tbody>
        <!-- Group by SOC -->
        <xsl:for-each-group select="$resources/fhir:ClinicalUseDefinition[fhir:type/@value = 'undesirable-effect']" group-by="fhir:undesirableEffect/fhir:classification/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/mdr']/fhir:code/@value">
          <xsl:variable name="frequencies" as="text()*">
            <xsl:for-each select="distinct-values(current-group()/fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:code/@value)">
              <xsl:value-of select="."/>
            </xsl:for-each>
          </xsl:variable>
          <xsl:choose>
            <xsl:when test="count($frequencies) = 1">
              <tr>
                <!-- SoC -->
                <td>
                  <xsl:value-of select="current-group()[1]/fhir:undesirableEffect/fhir:classification/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/mdr']/fhir:display/@value"/>
                </td>
                <!-- Frequency -->
                <xsl:variable name="effectsWithSocAndFrequency" select="current-group()[fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:code/@value = $frequencies[1]]"/>
                <td>
                  <xsl:value-of select="$effectsWithSocAndFrequency[1]/fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:display/@value"/>
                </td>
                <!-- Effects -->
                <td>
                  <xsl:for-each select="$effectsWithSocAndFrequency">
                    <xsl:apply-templates select="$effectsWithSocAndFrequency" mode="section4-8"/>
                  </xsl:for-each>
                </td>
              </tr>
              <!-- Simple row -->
            </xsl:when>
            <xsl:otherwise>
              <!-- The SoC should wrap all frequency rows -->
              <!-- First row, with frequency -->
              <tr>
                <!-- SoC -->
                <td rowspan="{count($frequencies)}">
                  <xsl:value-of select="current-group()[1]/fhir:undesirableEffect/fhir:classification/fhir:coding[fhir:system/@value = 'http://terminology.hl7.org/CodeSystem/mdr']/fhir:display/@value"/>
                </td>
                <!-- Frequency -->
                <xsl:variable name="effectsWithSocAndFrequency" select="current-group()[fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:code/@value = $frequencies[1]]"/>
                <td>
                  <xsl:value-of select="$effectsWithSocAndFrequency[1]/fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:display/@value"/>
                </td>
                <!-- Effects -->
                <td>
                  <xsl:for-each select="$effectsWithSocAndFrequency">
                    <xsl:apply-templates select="$effectsWithSocAndFrequency" mode="section4-8"/>
                  </xsl:for-each>
                </td>
              </tr>
              <!-- Subsequent rows -->
              <xsl:for-each select="$frequencies[position() > 1]">
                <xsl:variable name="currentFrequency" select="."/>
                <tr>
                  <!-- Frequency -->
                  <xsl:variable name="effectsWithSocAndFrequency" select="current-group()[fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:code/@value = $currentFrequency]"/>
                  <td>
                    <xsl:value-of select="$effectsWithSocAndFrequency[1]/fhir:undesirableEffect/fhir:frequencyOfOccurrence/fhir:coding[fhir:system/@value = 'https://gravitatehealth.eu/meddra/frequency']/fhir:display/@value"/>
                  </td>
                  <!-- Effects -->
                  <td>
                    <xsl:for-each select="$effectsWithSocAndFrequency">
                      <xsl:apply-templates select="$effectsWithSocAndFrequency" mode="section4-8"/>
                    </xsl:for-each>
                  </td>
                </tr>
              </xsl:for-each>
            </xsl:otherwise>
          </xsl:choose>
        </xsl:for-each-group>
      </tbody>
    </table>
  </xsl:template>

  <!-- The side effect, either from narrative or from the coded value -->
  <xsl:template match="fhir:ClinicalUseDefinition" mode="section4-8">
    <xsl:choose>
      <!-- First priority is the narrative -->
      <xsl:when test="fhir:text/html:div">
        <xsl:copy-of select="fhir:text/html:div"/>
      </xsl:when>
      <!-- Second priority is the text of the CodeableConcept -->
      <xsl:when test="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:text">
        <span xmlns="http://www.w3.org/1999/xhtml" class="id-ref-{fhir:id/@value}">
          <xsl:value-of select="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:text/@value"/>
        </span>
      </xsl:when>
      <!-- Third priority is the display of the first coding -->
      <xsl:when test="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:coding/fhir:display">
        <span xmlns="http://www.w3.org/1999/xhtml" class="id-ref-{fhir:id/@value}">
          <xsl:value-of select="fhir:undesirableEffect/fhir:symptomConditionEffect/fhir:concept/fhir:coding[1]/fhir:display/@value"/>
        </span>
      </xsl:when>
    </xsl:choose>
  </xsl:template>

</xsl:stylesheet>
