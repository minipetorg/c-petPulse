import '../models/pet.dart';

class PetController {
  final List<Pet> _pets = [];

  List<Pet> get pets => List.unmodifiable(_pets);

  void addPet(Pet pet) {
    _pets.add(pet);
  }

  void updatePet(int index, Pet pet) {
    _pets[index] = pet;
  }

  void deletePet(int index) {
    _pets.removeAt(index);
  }
}
