---
title: "7.1. Solution #1"
weight: 71
sectionnumber: 7.1
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

Find the releases of the software online and update them in youre files. Apply the changes to verfify everything is working well.

