# JSONLStream
JSON Lines implementation supporting reading as AsyncStreams and continuous writing


example of streaming read:
```
if let reader = JSONLReader(fileURL: fileURL) {
   for await myDecodable: MyDecodable in reader.objects() {
      // do something with this object
   }
}
```

example full read usage:
```
if let reader = JSONLReader(fileURL: fileURL) {
    let records: [MyDecodable] = await reader.allObjects()
}
```

example write usage:
```
let writer = JSONLWriter(fileURL: fileURL, appendIfExists: true)
try? await writer?.write(jsonObject: anchor)
```

