#Create AWS Backup Vault
resource "aws_backup_vault" "my_backup_vault" {
  name        = "My_Backup_Vault"
  #kms_key_arn = aws_kms_key.example.arn
}

# Create an AWS Backup
resource "aws_backup_plan" "my_backup_plan" {
  name = "My_Backup_Plan"
  rule {
    rule_name         = "My_Backup_Rule"
    target_vault_name = aws_backup_vault.my_backup_vault.name
    schedule          = "cron(0 10 * * ? *)"

    lifecycle {
      cold_storage_after = "90"
      delete_after       = "365"
    }
    recovery_point_tags = {
      Name = "My Backup Tag"
    }
  }
}
