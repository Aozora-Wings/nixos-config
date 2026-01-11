# convert-and-encrypt.sh

# 输入字体文件
INPUT_FONT="/home/wt/Downloads/MonoLisa-Complete-stable/ttf/MonoLisaVariableNormal.ttf"
OUTPUT_ENCRYPTED="MonoLisaVariableNormal.age"

# 方法1: 使用 base64 编码为文本
echo "使用 base64 编码转换..."
cat "$INPUT_FONT" | base64 -w0 | \
  agenix -e "$OUTPUT_ENCRYPTED"

echo "已加密保存到: $OUTPUT_ENCRYPTED"

# 方法2: 使用 xxd 生成 C 风格的十六进制数组（可选）
# cat "$INPUT_FONT" | xxd -i | \
#   agenix -e "monolisa-hex.age"
