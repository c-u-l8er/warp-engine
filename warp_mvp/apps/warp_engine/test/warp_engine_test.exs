defmodule WarpEngineTest do
  use ExUnit.Case, async: true

  alias WarpEngine.GeoObject

  setup do
    # Start WarpEngine application for each test
    {:ok, _} = Application.ensure_all_started(:warp_engine)

    # Ensure cleanup after each test
    on_exit(fn -> Application.stop(:warp_engine) end)

    :ok
  end

  describe "GeoObject" do
    test "creates a new GeoObject with default metadata" do
      object = GeoObject.new("test-1", {37.7749, -122.4194}, :point, %{"name" => "Test Point"})

      assert object.id == "test-1"
      assert object.coordinates == {37.7749, -122.4194}
      assert object.geometry == :point
      assert object.properties["name"] == "Test Point"
      assert object.metadata.access_frequency == 0.0
      assert object.metadata.data_mass == 1.0
    end

    test "validates coordinates correctly" do
      assert {:ok, {37.7749, -122.4194}} = GeoObject.validate_coordinates(37.7749, -122.4194)
      assert {:error, _} = GeoObject.validate_coordinates(91.0, -122.4194)  # Invalid lat
      assert {:error, _} = GeoObject.validate_coordinates(37.7749, -181.0)  # Invalid lon
      assert {:error, _} = GeoObject.validate_coordinates("invalid", "invalid")
    end

    test "calculates data mass based on properties" do
      object = GeoObject.new("test-1", {37.7749, -122.4194}, :point, %{"name" => "Test", "category" => "test"})
      mass = GeoObject.calculate_data_mass(object)

      assert mass > 1.0  # Base mass + property mass
    end

    test "records access and updates metadata" do
      object = GeoObject.new("test-1", {37.7749, -122.4194}, :point, %{})
      updated_object = GeoObject.record_access(object)

      assert updated_object.metadata.access_frequency > 0.0
      assert updated_object.updated_at > object.created_at
    end

    test "converts to GeoJSON format" do
      object = GeoObject.new("test-1", {37.7749, -122.4194}, :point, %{"name" => "Test"})
      geojson = GeoObject.to_geojson(object)

      assert geojson["type"] == "Feature"
      assert geojson["id"] == "test-1"
      assert geojson["geometry"]["type"] == "Point"
      assert geojson["geometry"]["coordinates"] == [-122.4194, 37.7749]  # GeoJSON uses [lon, lat]
      assert geojson["properties"]["name"] == "Test"
    end
  end

  describe "InputValidator" do
    test "validates object IDs" do
      assert {:ok, "valid-id"} = WarpEngine.InputValidator.validate_object_id("valid-id")
      assert {:error, _} = WarpEngine.InputValidator.validate_object_id("")
      assert {:error, _} = WarpEngine.InputValidator.validate_object_id(String.duplicate("a", 256))
    end

    test "validates bounding boxes" do
      assert {:ok, {37.0, -122.0, 38.0, -121.0}} =
        WarpEngine.InputValidator.validate_bbox(37.0, -122.0, 38.0, -121.0)

      assert {:error, _} = WarpEngine.InputValidator.validate_bbox(38.0, -122.0, 37.0, -121.0)  # Invalid order
      assert {:error, _} = WarpEngine.InputValidator.validate_bbox(0.0, -200.0, 1.0, -199.0)    # Invalid coords
    end

    test "validates radius search parameters" do
      assert {:ok, {37.7749, -122.4194, 1000}} =
        WarpEngine.InputValidator.validate_radius_search(37.7749, -122.4194, 1000)

      assert {:error, _} = WarpEngine.InputValidator.validate_radius_search(37.7749, -122.4194, -100)  # Negative radius
      assert {:error, _} = WarpEngine.InputValidator.validate_radius_search(37.7749, -122.4194, 200_000)  # Too large
    end
  end

  describe "WarpEngine API" do
    test "stores and retrieves spatial objects" do
      data = %{
        coordinates: {37.7749, -122.4194},
        properties: %{"name" => "Test Restaurant", "rating" => 4.5}
      }

      assert {:ok, :stored, shard_id, _time} = WarpEngine.put("restaurant-1", data)
      assert {:ok, object, ^shard_id, _time} = WarpEngine.get("restaurant-1")

      assert object.id == "restaurant-1"
      assert object.coordinates == {37.7749, -122.4194}
      assert object.properties["name"] == "Test Restaurant"
      assert object.properties["rating"] == 4.5
    end

    test "handles invalid coordinates" do
      data = %{
        coordinates: {91.0, -200.0},  # Invalid coordinates
        properties: %{}
      }

      # The actual error message is more specific about validation
      assert {:error, error_msg} = WarpEngine.put("invalid-1", data)
      assert is_binary(error_msg)
      assert String.contains?(error_msg, "Latitude")
    end

    test "updates existing objects" do
      # Create object
      data = %{coordinates: {37.7749, -122.4194}, properties: %{"name" => "Old Name"}}
      {:ok, :stored, _shard, _time} = WarpEngine.put("update-test", data)

      # Update object
      updates = %{properties: %{"name" => "New Name", "updated" => true}}
      assert {:ok, :updated, _shard, _time} = WarpEngine.update("update-test", updates)

      # Verify update
      {:ok, updated_object, _shard, _time} = WarpEngine.get("update-test")
      assert updated_object.properties["name"] == "New Name"
      assert updated_object.properties["updated"] == true
    end

    test "deletes objects" do
      # Create object
      data = %{coordinates: {37.7749, -122.4194}, properties: %{}}
      {:ok, :stored, _shard, _time} = WarpEngine.put("delete-test", data)

      # Delete object
      assert :ok = WarpEngine.delete("delete-test")

      # Verify deletion
      assert {:error, :not_found} = WarpEngine.get("delete-test")
    end

    test "performs bounding box searches" do
      # Create test objects
      objects = [
        {"sf-point", {37.7749, -122.4194}},
        {"oakland-point", {37.8044, -122.2711}},
        {"la-point", {34.0522, -118.2437}}  # Outside bay area
      ]

      Enum.each(objects, fn {id, {lat, lon}} ->
        data = %{coordinates: {lat, lon}, properties: %{"name" => id}}
        WarpEngine.put(id, data)
      end)

      # Search bay area bounding box
      bbox = {37.0, -123.0, 38.0, -122.0}
      {:ok, results} = WarpEngine.bbox_search(bbox)

      result_ids = Enum.map(results, & &1.id)
      assert "sf-point" in result_ids
      assert "oakland-point" in result_ids
      refute "la-point" in result_ids
    end

    test "performs radius searches" do
      # Create test objects
      center = {37.7749, -122.4194}  # San Francisco
      objects = [
        {"nearby-1", {37.7750, -122.4195}},  # Very close
        {"nearby-2", {37.7800, -122.4200}},  # Within 1km
        {"far-1", {37.8000, -122.4000}}      # Far away
      ]

      Enum.each(objects, fn {id, {lat, lon}} ->
        data = %{coordinates: {lat, lon}, properties: %{"name" => id}}
        WarpEngine.put(id, data)
      end)

      # Search within 1km radius
      {:ok, results} = WarpEngine.radius_search(center, 1000)

      result_ids = Enum.map(results, & &1.id)
      assert "nearby-1" in result_ids
      assert "nearby-2" in result_ids
      refute "far-1" in result_ids
    end

    test "provides system statistics" do
      stats = WarpEngine.get_stats()

      assert Map.has_key?(stats, :shard_count)
      assert Map.has_key?(stats, :total_objects)
      assert Map.has_key?(stats, :total_memory_bytes)
      assert Map.has_key?(stats, :shards)
    end

    test "provides health check" do
      assert {:ok, health_data} = WarpEngine.health_check()
      assert health_data.status == :healthy
      assert Map.has_key?(health_data, :stats)
    end
  end
end
