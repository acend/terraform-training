---
title: "7. Cleanup"
weight: 7
sectionnumber: 7
---

To finish the lab and destroy all cloud resources managed by Terraform, please run the following command:

```bash
cd $LAB_ROOT/azure
terraform destroy -var-file=config/dev.tfvars
az group delete --name rg-terraform-$NAME
cd $LAB_ROOT/azure/aci
terraform destroy
```

Thank you!
