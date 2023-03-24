# Create an AWS Backup
resource "aws_backup_plan" "my_backup_plan" {
  name = "My_Backup_Plan"
  rule {
    rule_name         = "My_Backup_Rule"
    target_vault_name = "My_Backup_Vault"
    schedule          = "cron(0 10 * * ? *)"
    #schedule  {
    #  frequency  = "daily"
    #  start_time = "10:00"
    #}
    lifecycle {
      cold_storage_after = "90"
      delete_after       = "365"
    }
    recovery_point_tags = {
      Name = "My Backup Tag"
    }
  }
}
