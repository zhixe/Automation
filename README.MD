<!-- GOLANG mod file -->
### 1. Generate go mod file first
go mod init sampleProjectName

### 2. Then use tidy to detect the external libraries and update it
go mod tidy

### 3. Use go get to download the external library (just like python pip install)
go get github.com/icrowley/fake
