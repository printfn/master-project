resource aws_s3_bucket "l42_bucket" {
  bucket_prefix = "l42-"
  force_destroy = true
}

resource "aws_s3_bucket_acl" "l42_bucket" {
  bucket = aws_s3_bucket.l42_bucket.id
  acl    = "private"
}

resource "aws_s3_bucket_public_access_block" "l42_bucket" {
  # provider = aws.eu-west-2

  bucket = aws_s3_bucket.l42_bucket.id

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_acls = true

  # Whether Amazon S3 should block public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the existing bucket policy. When set to true causes Amazon S3 to:
  # Reject calls to PUT Bucket policy if the specified bucket policy allows public access.
  block_public_policy = true

  # Whether Amazon S3 should ignore public ACLs for this bucket. Defaults to false.
  # Enabling this setting does not affect the persistence of any existing ACLs and doesn't prevent new public ACLs from being set. When set to true causes Amazon S3 to:
  # Ignore public ACLs on this bucket and any objects that it contains.
  ignore_public_acls = true

  # Whether Amazon S3 should restrict public bucket policies for this bucket. Defaults to false.
  # Enabling this setting does not affect the previously stored bucket policy, except that public and cross-account access within the public bucket policy,
  # including non-public delegation to specific accounts, is blocked. When set to true:
  # Only the bucket owner and AWS Services can access this buckets if it has a public policy.
  restrict_public_buckets = true
}
