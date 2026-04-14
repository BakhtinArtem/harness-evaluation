package org.quarkus.samples.petclinic.rest;

import java.time.LocalDate;
import java.util.List;

class OwnerDto {
    public Long id;
    public String firstName;
    public String lastName;
    public String address;
    public String city;
    public String telephone;
}

class PetDto {
    public Long id;
    public String name;
    public LocalDate birthDate;
    public Long typeId;
    public Long ownerId;
}

class VisitDto {
    public Long id;
    public LocalDate date;
    public String description;
    public Long petId;
}

class VetDto {
    public Long id;
    public String firstName;
    public String lastName;
    public List<Long> specialtyIds;
}

class SpecialtyDto {
    public Long id;
    public String name;
}

class PetTypeDto {
    public Long id;
    public String name;
}
