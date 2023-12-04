<!-- GOLANG mod file -->
# Generate go mod file first
go mod init sampleProjectName

# Then use tidy to detect the external libraries and update it
go mod tidy

# Use go get to download the external library (just like python pip install)
go get github.com/icrowley/fake
