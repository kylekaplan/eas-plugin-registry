### Known caveats
- pluginId must be the first item in the array when encoding the data.
For example:
```
encodedData = schemaEncoder.encodeData([
  { name: 'pluginId', value: pluginId, type: 'bytes32' }, // pluginId is first
  { name: 'details', value: detailsId, type: 'bytes32' },
]);
```

- SchemaResolver `onAttest`` is an internal function, so an external function name `publicOnAttest` must be included in PluginResolvers. They may inherit `IPluginResolver`.