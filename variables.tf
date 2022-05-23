variable "project_name" {
  description = "value"
  type        = string
}

variable "project_id" {
  description = "value"
  type        = string
}

variable "big_robot_name" {
  description = "value"
  type        = string
}

variable "big_robot_group" {
  description = "value"
  type        = string
}


variable "organization" {
  description = "value"
  type        = string
}

variable "organization_id" {
  description = "gcloud projects describe <project> --format='value(parent.id)'"
  type        = string
}

variable "location" {
  description = "value"
  type        = string
}

variable "main_availability_zone" {
  description = "value"
  type        = string
}

variable "keyring" {
  description = "value"
  type        = string
}

variable "keyring_key" {
  description = "value"
  type        = string
}

variable "credentials_path" {
  description = "value"
  type        = string
}

variable "billing_account" {
  description = "value"
  type        = string
}

variable "backend_bucket_name" {
  description = "value"
  type        = string
  default     = "slim"
}

variable "bucket_path_prefix" {
  description = "value"
  type        = string
}