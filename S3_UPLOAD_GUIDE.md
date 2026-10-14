# Database Dump with Automatic S3 Upload

## 📋 Overview

This script automatically:
1. ✅ Dumps India production database with PII masking
2. ✅ Compresses on-the-fly (streaming compression)
3. ✅ Uploads to S3 bucket automatically after completion
4. ✅ Optionally deletes local copy to save space

**Benefits:**
- No need to manually transfer 162 GB file
- Much faster download from S3 to local machine
- Saves disk space on database pod
- Automated workflow

---

## 🚀 Quick Start

### **Step 1: Setup AWS Credentials in Pod**

```bash
# Connect to database pod
kubectl exec -it simple-instance1-7cl2-0 -n simple-v1 -- bash

# Configure AWS CLI (if not already configured)
aws configure
# Enter:
# - AWS Access Key ID
# - AWS Secret Access Key
# - Default region (e.g., ap-south-1)
# - Output format: json

# Test S3 access
aws s3 ls s3://your-bucket-name/
```

### **Step 2: Copy Script to Pod**

```bash
# From local machine
kubectl cp /Users/sagar/Downloads/dump_simple_script/simple_migration_tools/full_db_dump_mask_pii_streaming_s3.sh \
  simple-v1/simple-instance1-7cl2-0:/tmp/dump_with_s3.sh
```

### **Step 3: Run Script with S3 Upload**

```bash
# In the pod
chmod +x /tmp/dump_with_s3.sh

# Run with S3 upload (replace with your bucket)
nohup /tmp/dump_with_s3.sh postgres localhost simple_db_india_production_001 s3://your-bucket-name/dumps/ \
  > /tmp/dump_s3.log 2>&1 &

# Check it's running
ps aux | grep dump_with_s3

# Monitor progress
tail -f /tmp/dump_s3.log
```

---

## 📊 Expected Timeline:

| Phase | Time | Description |
|-------|------|-------------|
| **Dump + Compress** | 4-6 hours | Creates compressed dump file (~162 GB) |
| **Upload to S3** | 5-15 minutes | Uploads from pod to S3 (very fast!) |
| **Download from S3** | 1-3 hours | Download from S3 to local machine |
| **Total** | ~5-9 hours | Mostly automated |

**vs kubectl cp:** 21+ hours direct download!

---

## 📥 Download from S3 to Local Machine

After dump completes and uploads to S3:

```bash
# From your local machine
aws s3 cp s3://your-bucket-name/dumps/india_prod_dump_masked_YYYYMMDD_HHMMSS.sql.gz \
  ./india_prod_dump_masked_162GB.sql.gz

# Check progress
ls -lh india_prod_dump_masked_162GB.sql.gz

# This is MUCH faster than kubectl cp!
```

---

## 🔧 Configuration Options

### **Basic Usage (No S3):**
```bash
./dump_with_s3.sh postgres localhost simple_db_india_production_001
# No S3 upload, just creates local dump
```

### **With S3 Upload:**
```bash
./dump_with_s3.sh postgres localhost simple_db_india_production_001 s3://my-bucket/dumps/
# Dumps AND uploads to S3
```

### **With Different Database:**
```bash
./dump_with_s3.sh postgres remote-host my_other_database s3://my-bucket/dumps/
# Specify different host and database
```

---

## ✅ Features

### **Automatic S3 Upload:**
- Uploads immediately after dump completes
- Shows upload progress
- Verifies upload success

### **Space Saving:**
- Option to delete local file after S3 upload
- Saves 162 GB on pod
- Keep only S3 copy

### **Error Handling:**
- If S3 upload fails, keeps local copy
- AWS CLI not required if S3 disabled
- Graceful fallback

---

## 🆘 Troubleshooting

### **AWS CLI not found:**
```bash
# Install AWS CLI in pod (if needed)
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Or use pip
pip install awscli
```

### **AWS credentials not configured:**
```bash
# Configure credentials
aws configure

# Or set environment variables
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="ap-south-1"
```

### **S3 upload fails:**
```bash
# Check S3 permissions
aws s3 ls s3://your-bucket-name/

# Test upload
echo "test" | aws s3 cp - s3://your-bucket-name/test.txt

# Check IAM permissions (need s3:PutObject)
```

### **Upload too slow:**
```bash
# Check if using correct region
# Bucket and pod should be in same AWS region for fastest upload

# Check bucket location
aws s3api get-bucket-location --bucket your-bucket-name
```

---

## 💡 Best Practices

### **1. Use Same Region:**
- Put S3 bucket in same AWS region as EKS cluster
- This makes upload VERY fast (5-10 minutes)

### **2. Enable S3 Transfer Acceleration:**
```bash
# Enable on bucket (if supported)
aws s3api put-bucket-accelerate-configuration \
  --bucket your-bucket-name \
  --accelerate-configuration Status=Enabled

# Then use accelerate endpoint
./dump_with_s3.sh postgres localhost simple_db_india_production_001 \
  s3://your-bucket-name.s3-accelerate.amazonaws.com/dumps/
```

### **3. Use S3 Lifecycle Policy:**
```bash
# Auto-delete old dumps after 30 days
aws s3api put-bucket-lifecycle-configuration \
  --bucket your-bucket-name \
  --lifecycle-configuration file://lifecycle.json
```

Example `lifecycle.json`:
```json
{
  "Rules": [
    {
      "Id": "DeleteOldDumps",
      "Prefix": "dumps/",
      "Status": "Enabled",
      "Expiration": {
        "Days": 30
      }
    }
  ]
}
```

### **4. Monitor S3 Upload:**
```bash
# Watch S3 upload progress in log
tail -f /tmp/dump_s3.log | grep -E "upload|Completed"
```

---

## 📋 Complete Example

```bash
# 1. Setup (one-time)
kubectl exec -it simple-instance1-7cl2-0 -n simple-v1 -- bash
aws configure  # Enter credentials

# 2. Copy script
exit
kubectl cp full_db_dump_mask_pii_streaming_s3.sh \
  simple-v1/simple-instance1-7cl2-0:/tmp/dump_with_s3.sh

# 3. Run dump with S3 upload
kubectl exec -it simple-instance1-7cl2-0 -n simple-v1 -- bash
chmod +x /tmp/dump_with_s3.sh
nohup /tmp/dump_with_s3.sh postgres localhost simple_db_india_production_001 \
  s3://my-backups/india-prod-dumps/ > /tmp/dump_s3.log 2>&1 &

# 4. Monitor (optional)
tail -f /tmp/dump_s3.log

# 5. After completion (~6 hours), download from S3
exit
aws s3 cp s3://my-backups/india-prod-dumps/india_prod_dump_masked_20261014_120000.sql.gz \
  ./india_prod_dump_162GB.sql.gz

# Much faster than kubectl cp! (~1-3 hours vs 21 hours)
```

---

## 🎯 Comparison

| Method | Time | Complexity | Reliability |
|--------|------|------------|-------------|
| **kubectl cp** | 21+ hours | Simple | Poor (connection drops) |
| **Dump + S3 + Download** | ~6-9 hours | Medium | Excellent |
| **Split files** | ~15-20 hours | Complex | Medium |

**Recommended:** Dump + S3 + Download ✅

---

## 🔒 Security Notes

- ✅ Dump contains masked PII (safe)
- ✅ Use S3 bucket encryption (AES-256 or KMS)
- ✅ Enable S3 bucket versioning
- ✅ Restrict IAM permissions (only s3:PutObject/GetObject needed)
- ⚠️ Still contains sensitive medical data - handle with care
- ⚠️ Use private S3 bucket (not public)

---

## 📞 Support

For issues:
1. Check AWS credentials: `aws sts get-caller-identity`
2. Check S3 access: `aws s3 ls s3://your-bucket/`
3. Check dump log: `tail -100 /tmp/dump_s3.log`
4. Verify disk space: `df -h /pgdata`

---

**🚀 Much faster than kubectl cp! Recommended for large dumps!**
