package org.quarkus.samples.petclinic;

import io.quarkus.test.junit.QuarkusTest;
import org.junit.jupiter.api.Test;

import static io.restassured.RestAssured.given;
import static io.restassured.RestAssured.when;
import static org.hamcrest.Matchers.equalTo;
import static org.hamcrest.Matchers.notNullValue;

@QuarkusTest
class ApiContractAndFlowTest {

    @Test
    void servesOpenApiWithStatefulLinks() {
        when().get("/q/openapi")
            .then()
            .statusCode(200)
            .body(org.hamcrest.Matchers.containsString("operationId: addOwner"))
            .body(org.hamcrest.Matchers.containsString("DeletePetAfterUpdate"))
            .body(org.hamcrest.Matchers.containsString("UpdateCreatedSpecialty"));
    }

    @Test
    void ownerToPetCrudFlowWorks() {
        Long ownerId = given()
            .contentType("application/json")
            .body("""
                {
                  "firstName":"Flow",
                  "lastName":"Owner",
                  "address":"123 Test St",
                  "city":"Testville",
                  "telephone":"5551234567"
                }
                """)
            .when()
            .post("/api/owners")
            .then()
            .statusCode(201)
            .body("id", notNullValue())
            .extract()
            .jsonPath()
            .getLong("id");

        given()
            .contentType("application/json")
            .body("""
                {
                  "id": %d,
                  "firstName":"FlowUpdated",
                  "lastName":"Owner",
                  "address":"123 Test St",
                  "city":"Testville",
                  "telephone":"5551234567"
                }
                """.formatted(ownerId))
            .when()
            .put("/api/owners/{ownerId}", ownerId)
            .then()
            .statusCode(200)
            .body("id", equalTo(ownerId.intValue()))
            .body("firstName", equalTo("FlowUpdated"));

        Long petId = given()
            .contentType("application/json")
            .body("""
                {
                  "name":"FlowPet",
                  "birthDate":"2020-01-01",
                  "typeId":1001
                }
                """)
            .when()
            .post("/api/owners/{ownerId}/pets", ownerId)
            .then()
            .statusCode(201)
            .body("id", notNullValue())
            .body("ownerId", equalTo(ownerId.intValue()))
            .extract()
            .jsonPath()
            .getLong("id");

        given()
            .contentType("application/json")
            .body("""
                {
                  "id": %d,
                  "name":"FlowPetUpdated",
                  "birthDate":"2020-02-02",
                  "typeId":1002
                }
                """.formatted(petId))
            .when()
            .put("/api/pets/{petId}", petId)
            .then()
            .statusCode(200)
            .body("id", equalTo(petId.intValue()))
            .body("name", equalTo("FlowPetUpdated"));

        when().delete("/api/pets/{petId}", petId).then().statusCode(204);
        when().delete("/api/owners/{ownerId}", ownerId).then().statusCode(204);
    }
}
