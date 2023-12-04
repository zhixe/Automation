package main

import (
	"encoding/csv"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"strings"
	"time"

	gofakeit "github.com/brianvoe/gofakeit/v6"
	fake "github.com/icrowley/fake"
)

// Product struct to hold the UUID and name of a product
type Product struct {
	UUID string
	Name string
}

func main() {
	start := time.Now()

	// Check if the output file exists
	filename := "sales_data.csv"
	_, err := os.Stat(filename)

	uniqueProducts := generateUniqueProducts(100)
	staffNames := generateRandomStaff()

	// If the file does not exist, generate 1000000 rows of sales data
	// Otherwise, generate a random number of rows
	var data [][]string
	if os.IsNotExist(err) {
		data = generateSalesData(1000000, staffNames, uniqueProducts)
	} else {
		data = generateSalesDataRandom(staffNames, uniqueProducts)
	}

	// Print the number of rows that have been generated
	fmt.Printf("Generated %d rows of data\n", len(data)-1) // Subtract 1 for the header row

	// Save data to CSV file
	err = saveToCSV(data, "sales_data.csv") // Use = instead of :=
	if err != nil {
		fmt.Println("Error:", err)
		return
	}

	elapsed := time.Since(start)
	fmt.Printf("Sales data generated and saved to sales_data.csv in %s\n", elapsed)
}

func generateSalesDataRandom(staffNames []string, uniqueProducts []Product) [][]string {
	// Set random seed
	rand.Seed(time.Now().UnixNano())

	// Generate header row
	header := []string{"ProductID", "ProductName", "Price", "Quantity", "Total", "Discount", "Tax", "Shipping", "Profit", "StaffName", "OrderDate"}

	// Determine the number of rows based on a weighted random number
	numRows := weightedRandomNumber()

	// Generate data rows
	data := make([][]string, numRows+1)
	data[0] = header
	for i := 1; i <= numRows; i++ {
		product := uniqueProducts[rand.Intn(len(uniqueProducts))]
		productID := product.UUID
		productName := product.Name
		price := generateRandomPrice()
		quantity := generateRandomQuantity()
		total := price * float64(quantity)
		discount := generateRandomDiscount()
		tax := generateRandomTax()
		shipping := generateRandomShipping()
		profit := total - discount - tax - shipping
		staff := staffNames[rand.Intn(len(staffNames))]
		date := generateRandomDate().Format("2006-01-02")

		row := []string{
			productID,
			productName,
			strconv.FormatFloat(price, 'f', 2, 64),
			strconv.Itoa(quantity),
			strconv.FormatFloat(total, 'f', 2, 64),
			strconv.FormatFloat(discount, 'f', 2, 64),
			strconv.FormatFloat(tax, 'f', 2, 64),
			strconv.FormatFloat(shipping, 'f', 2, 64),
			strconv.FormatFloat(profit, 'f', 2, 64),
			staff,
			date,
		}

		data[i] = row
	}

	return data
}

func generateSalesData(numRows int, staffNames []string, uniqueProducts []Product) [][]string {
	// Set random seed
	rand.Seed(time.Now().UnixNano())

	// Generate header row
	header := []string{"ProductID", "ProductName", "Price", "Quantity", "Total", "Discount", "Tax", "Shipping", "Profit", "StaffName", "OrderDate"}

	// Generate data rows
	data := make([][]string, numRows+1)
	data[0] = header
	for i := 1; i <= numRows; i++ {
		product := uniqueProducts[rand.Intn(len(uniqueProducts))]
		productID := product.UUID
		productName := product.Name
		price := generateRandomPrice()
		quantity := generateRandomQuantity()
		total := price * float64(quantity)
		discount := generateRandomDiscount()
		tax := generateRandomTax()
		shipping := generateRandomShipping()
		profit := total - discount - tax - shipping
		staff := staffNames[rand.Intn(len(staffNames))]
		date := generateRandomDate().Format("2006-01-02")

		row := []string{
			productID,
			productName,
			strconv.FormatFloat(price, 'f', 2, 64),
			strconv.Itoa(quantity),
			strconv.FormatFloat(total, 'f', 2, 64),
			strconv.FormatFloat(discount, 'f', 2, 64),
			strconv.FormatFloat(tax, 'f', 2, 64),
			strconv.FormatFloat(shipping, 'f', 2, 64),
			strconv.FormatFloat(profit, 'f', 2, 64),
			staff,
			date,
		}

		data[i] = row
	}

	return data
}

func weightedRandomNumber() int {
	// Generate a random number between 1 and 100
	r := rand.Intn(100) + 1

	switch {
	case r <= 50: // 50% chance
		// Return a random number between 1 and 10
		return rand.Intn(10) + 1
	case r <= 80: // 30% chance
		// Return a random number between 1 and 100
		return rand.Intn(100) + 1
	case r <= 95: // 15% chance
		// Return a random number between 1 and 1000
		return rand.Intn(1000) + 1
	default: // 5% chance
		// Return a random number between 1 and 10000
		return rand.Intn(10000) + 1
	}
}

func generateUniqueProducts(num int) []Product {
	var products []Product
	productNames := make([]string, num)

	for i := 0; i < num; i++ {
		productNames[i] = fake.Product()
	}

	for i := 0; i < num; i++ {
		abbreviation := generateAbbreviation(productNames[i])
		products = append(products, Product{
			UUID: abbreviation,
			Name: productNames[i],
		})
	}

	return products
}

func generateAbbreviation(productName string) string {
	words := strings.Fields(productName)
	var abbreviation string
	for _, word := range words {
		abbreviation += strings.ToUpper(string(word[0]))
	}

	return abbreviation
}

func generateRandomPrice() float64 {
	minPrice := 10.0
	maxPrice := 100.0
	return minPrice + rand.Float64()*(maxPrice-minPrice)
}

func generateRandomQuantity() int {
	minQuantity := 1
	maxQuantity := 10
	return rand.Intn(maxQuantity-minQuantity+1) + minQuantity
}

func generateRandomDiscount() float64 {
	minDiscount := 0.0
	maxDiscount := 20.0
	return minDiscount + rand.Float64()*(maxDiscount-minDiscount)
}

func generateRandomTax() float64 {
	minTax := 0.0
	maxTax := 10.0
	return minTax + rand.Float64()*(maxTax-minTax)
}

func generateRandomShipping() float64 {
	minShipping := 0.0
	maxShipping := 5.0
	return minShipping + rand.Float64()*(maxShipping-minShipping)
}

func generateRandomStaff() []string {
	var staffNames []string
	for i := 0; i < 20; i++ {
		staffNames = append(staffNames, gofakeit.Name())
	}
	return staffNames
}

func generateRandomDate() time.Time {
	min := time.Date(2010, 1, 1, 0, 0, 0, 0, time.UTC).Unix()
	max := time.Now().Unix()
	delta := max - min

	sec := rand.Int63n(delta) + min
	return time.Unix(sec, 0)
}

func saveToCSV(data [][]string, filename string) error {
	file, err := os.OpenFile(filename, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return err
	}
	defer file.Close()

	writer := csv.NewWriter(file)
	defer writer.Flush()

	// Check if the file is empty
	info, err := file.Stat()
	if err != nil {
		return err
	}

	// If the file is empty, write the header row
	if info.Size() == 0 {
		err := writer.Write(data[0])
		if err != nil {
			return err
		}
	}

	// Write the data rows
	for _, row := range data[1:] {
		err := writer.Write(row)
		if err != nil {
			return err
		}
	}

	return nil
}
