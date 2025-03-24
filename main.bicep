@description('Optional. Azure location for deployed resources.')
param location string = resourceGroup().location

@description('Required. Name of the Container Insights data collection rule.')
param containerInsightsDataCollectionRuleName string

@description('Required. Name of the VM Insights data collection rule.')
param vmInsightsDataCollectionRuleName string

@description('Required. Resource ID of the Log Analytics workspace.')
param logAnalyticsWorkspaceId string

@allowed([
  'Linux'
  'Windows'
])
@description('Optional. Kind of data collection rule. Deafult is Linux.')
param dataCollectionRuleKind string = 'Linux'

@description('Optional. Interval for data collection. Default is 1m.')
param dataCollectionRuleInterval string = '1m'

@description('Optional. Data Collection Rule namespace filtering mode. Default is Off.')
param dataCollectionRuleNamespaceFilteringMode string = 'Off'

@description('Optional. Enable Container Log V2. Default is true.')
param dataCollectionRuleEnableContainerLogV2 bool = true

@description('Optional. Tags for all resources.')
param tags object = {}


// Data collection rule for Container Insights
resource containerInsightsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2022-06-01' = {
  name: containerInsightsDataCollectionRuleName
  location: location
  kind: dataCollectionRuleKind
  tags: tags
  properties: {
    dataSources: {
      extensions: [
        {
          name: 'ContainerInsightsExtension'
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: dataCollectionRuleInterval
              namespaceFilteringMode: dataCollectionRuleNamespaceFilteringMode
              enableContainerLogV2: dataCollectionRuleEnableContainerLogV2
            }
          }
          streams: [
            'Microsoft-ContainerInsights-Group-Default'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalyticsWorkspaceId
          name: 'ciworkspace'
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-ContainerInsights-Group-Default'
        ]
        destinations: [
          'ciworkspace'
        ]
      }
    ]
  }
}

resource vmInsightsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2021-04-01' = {
  name: vmInsightsDataCollectionRuleName
  location: location
  tags: tags
  properties: {
    description: 'Data Collection Rule for VM Insights'
    dataSources: {
      performanceCounters: [
        {
          name: 'VMInsightsPerfCounters'
          streams: [
            'Microsoft-InsightsMetrics'
          ]
          samplingFrequencyInSeconds: 60
          counterSpecifiers: [
            '\\VmInsights\\DetailedMetrics'
          ]
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          name: 'VMInsightsPerf-Logs-Dest'
          workspaceResourceId: logAnalyticsWorkspaceId
        }
      ]
    }
    dataFlows: [
      {
        streams: [
          'Microsoft-InsightsMetrics'
        ]
        destinations: [
          'VMInsightsPerf-Logs-Dest'
        ]
      }
    ]
  }
}

output dataCollectionRuleId string = containerInsightsDataCollectionRule.id
output vmInsightsDataCollectionRuleId string = vmInsightsDataCollectionRule.id
