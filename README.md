# ardan-labs-learning

### Terraform Kind Setup
Run 
```
make kind-up
cd infrastructure
terraform init
terraform apply
```

## Module 3 
```
## Start it with
make kind-up
make kind-update-apply

## Confirm with
make kind-logs

## Down it
make kind-down
```

## Module 4 Notes
- Don’t wrap code in Go until it’s absolutely necessary. LESS IS MORE
- Leave a TODO list at the top of a file in comments
- doc.go can count for comments, especially when building shared packages 

TODO: Rewatch 4.6 cause I didn't understand any of it 
TODO: See about getting [expvarmon](https://github.com/divan/expvarmon) working