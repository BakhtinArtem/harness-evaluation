package org.quarkus.samples.petclinic.rest;

import org.quarkus.samples.petclinic.owner.Owner;
import org.quarkus.samples.petclinic.owner.Pet;
import org.quarkus.samples.petclinic.owner.PetType;
import org.quarkus.samples.petclinic.vet.Specialty;
import org.quarkus.samples.petclinic.vet.Vet;
import org.quarkus.samples.petclinic.visit.Visit;

import java.util.ArrayList;
import java.util.List;
import java.util.Set;

final class ApiMapper {
    private ApiMapper() {
    }

    static OwnerDto toOwnerDto(Owner owner) {
        OwnerDto dto = new OwnerDto();
        dto.id = owner.id;
        dto.firstName = owner.firstName;
        dto.lastName = owner.lastName;
        dto.address = owner.address;
        dto.city = owner.city;
        dto.telephone = owner.telephone;
        return dto;
    }

    static PetDto toPetDto(Pet pet) {
        PetDto dto = new PetDto();
        dto.id = pet.id;
        dto.name = pet.name;
        dto.birthDate = pet.birthDate;
        dto.typeId = pet.type != null ? pet.type.id : null;
        dto.ownerId = pet.owner != null ? pet.owner.id : null;
        return dto;
    }

    static VisitDto toVisitDto(Visit visit) {
        VisitDto dto = new VisitDto();
        dto.id = visit.id;
        dto.date = visit.date;
        dto.description = visit.description;
        dto.petId = visit.petId;
        return dto;
    }

    static VetDto toVetDto(Vet vet) {
        VetDto dto = new VetDto();
        dto.id = vet.id;
        dto.firstName = vet.firstName;
        dto.lastName = vet.lastName;
        List<Long> specialtyIds = new ArrayList<>();
        Set<Specialty> specialties = vet.specialties;
        if (specialties != null) {
            for (Specialty specialty : specialties) {
                specialtyIds.add(specialty.id);
            }
        }
        dto.specialtyIds = specialtyIds;
        return dto;
    }

    static SpecialtyDto toSpecialtyDto(Specialty specialty) {
        SpecialtyDto dto = new SpecialtyDto();
        dto.id = specialty.id;
        dto.name = specialty.name;
        return dto;
    }

    static PetTypeDto toPetTypeDto(PetType petType) {
        PetTypeDto dto = new PetTypeDto();
        dto.id = petType.id;
        dto.name = petType.name;
        return dto;
    }
}
