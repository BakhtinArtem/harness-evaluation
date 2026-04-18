package models

// Owner mirrors the Spring Petclinic Owner entity (table "owners").
type Owner struct {
	ID        int32  `gorm:"primaryKey;column:id" json:"id"`
	FirstName string `gorm:"column:first_name" json:"firstName"`
	LastName  string `gorm:"column:last_name" json:"lastName"`
	Address   string `gorm:"column:address" json:"address"`
	City      string `gorm:"column:city" json:"city"`
	Telephone string `gorm:"column:telephone" json:"telephone"`
	Pets      []Pet  `gorm:"foreignKey:OwnerID;references:ID" json:"pets"`
}

func (Owner) TableName() string { return "owners" }

// Pet mirrors the Spring Petclinic Pet entity (table "pets").
type Pet struct {
	ID        int32     `gorm:"primaryKey;column:id" json:"id"`
	Name      string    `gorm:"column:name" json:"name"`
	BirthDate LocalDate `gorm:"column:birth_date" json:"birthDate"`
	TypeID    int32     `gorm:"column:type_id" json:"-"`
	Type      PetType   `gorm:"foreignKey:TypeID;references:ID" json:"type"`
	OwnerID   *int32    `gorm:"column:owner_id" json:"ownerId,omitempty"`
	Visits    []Visit   `gorm:"foreignKey:PetID;references:ID" json:"visits"`
}

func (Pet) TableName() string { return "pets" }

// PetType mirrors the Spring Petclinic PetType entity (table "types").
type PetType struct {
	ID   int32  `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name" json:"name"`
}

func (PetType) TableName() string { return "types" }

// Visit mirrors the Spring Petclinic Visit entity (table "visits").
type Visit struct {
	ID          int32     `gorm:"primaryKey;column:id" json:"id"`
	PetID       int32     `gorm:"column:pet_id" json:"petId"`
	Date        LocalDate `gorm:"column:visit_date" json:"date"`
	Description string    `gorm:"column:description" json:"description"`
}

func (Visit) TableName() string { return "visits" }

// Vet mirrors the Spring Petclinic Vet entity (table "vets").
type Vet struct {
	ID          int32       `gorm:"primaryKey;column:id" json:"id"`
	FirstName   string      `gorm:"column:first_name" json:"firstName"`
	LastName    string      `gorm:"column:last_name" json:"lastName"`
	Specialties []Specialty `gorm:"many2many:vet_specialties;joinForeignKey:vet_id;joinReferences:specialty_id" json:"specialties"`
}

func (Vet) TableName() string { return "vets" }

// Specialty mirrors the Spring Petclinic Specialty entity (table "specialties").
type Specialty struct {
	ID   int32  `gorm:"primaryKey;column:id" json:"id"`
	Name string `gorm:"column:name" json:"name"`
}

func (Specialty) TableName() string { return "specialties" }

// User mirrors the Spring Petclinic User entity (table "users").
type User struct {
	Username string `gorm:"primaryKey;column:username" json:"username"`
	Password string `gorm:"column:password" json:"password,omitempty"`
	Enabled  bool   `gorm:"column:enabled" json:"enabled"`
	Roles    []Role `gorm:"foreignKey:Username;references:Username" json:"roles"`
}

func (User) TableName() string { return "users" }

// Role mirrors the Spring Petclinic Role entity (table "roles").
type Role struct {
	ID       int32  `gorm:"primaryKey;column:id" json:"-"`
	Username string `gorm:"column:username" json:"-"`
	Name     string `gorm:"column:role" json:"name"`
}

func (Role) TableName() string { return "roles" }
