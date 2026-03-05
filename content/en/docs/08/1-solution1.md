---
title: "8.1. Solution #1"
weight: 81
sectionnumber: 8.1
---

```mermaid
flowchart LR
    user --> |find|release
    subgraph local
      file
    end
    release --> |update|file
    file --> |apply|object
    subgraph azure
      object
    end
```

## Preparation

Check all the last chapters for versions.
* required_providers
* kubernetes_version
* helm_release

Find the releases of the software online and update them in your files. Apply the changes to verify everything is working well.

