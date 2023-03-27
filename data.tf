data "aws_prefix_list" "s3_pl" {
  name = "com.amazonaws.*.s3"
}

data "aws_ami" "app" {
  most_recent = true
  owners      = ["self", "amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.0.*-x86_64"]
  }
  # インスタンスを起動するときは、ルートデバイスボリュームに格納されているイメージを使用してインスタンスがブートされます。
  # Amazon EC2 のサービス開始当初は、すべての AMI がAmazon EC2 インスタンスストア backedでした。
  # つまり、AMI から起動されるインスタンスのルートデバイスは、Amazon S3 に格納されたテンプレートから作成されるインスタンスストアボリュームです。
  # Amazon EBS の導入後は Amazon EBS を基にした AMI も導入されました。
  # つまり、AMI から起動されるインスタンスのルートデバイスが、Amazon EBS スナップショットから作成される Amazon EBS ボリュームであるということです。
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
  # Linux Amazon マシンイメージ では、2 つの仮想化タイプ (準仮想化 (PV) およびハードウェア仮想マシン (HVM)) のどちらかを使用します
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}
