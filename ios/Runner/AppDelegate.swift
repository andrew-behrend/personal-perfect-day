import Flutter
import HealthKit
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private let healthStore = HKHealthStore()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let started = super.application(application, didFinishLaunchingWithOptions: launchOptions)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "perfect_day/healthkit",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak self] call, result in
        self?.handleHealthKitCall(call, result: result)
      }
    }

    return started
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private func handleHealthKitCall(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "connectionStatus":
      healthConnectionStatus(result: result)
    case "requestAuthorization":
      requestHealthAuthorization(result: result)
    case "importRange":
      importHealthRange(call: call, result: result)
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private func healthConnectionStatus(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result([
        "connected": false,
      ])
      return
    }

    let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)
    let status = sleepType.map { healthStore.authorizationStatus(for: $0) } ?? .notDetermined
    let connected = status == .sharingAuthorized

    result([
      "connected": connected,
      "lastSyncAtMs": NSNull(),
    ])
  }

  private func requestHealthAuthorization(result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result(false)
      return
    }

    guard
      let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis),
      let restingType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)
    else {
      result(false)
      return
    }

    let readTypes: Set<HKObjectType> = [
      sleepType,
      HKObjectType.workoutType(),
      restingType,
    ]

    healthStore.requestAuthorization(toShare: nil, read: readTypes) { success, _ in
      DispatchQueue.main.async {
        result(success)
      }
    }
  }

  private func importHealthRange(call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard HKHealthStore.isHealthDataAvailable() else {
      result([])
      return
    }

    guard
      let args = call.arguments as? [String: Any],
      let fromMs = args["fromMs"] as? Double,
      let toMs = args["toMs"] as? Double
    else {
      result(FlutterError(code: "bad_args", message: "Missing from/to", details: nil))
      return
    }

    let from = Date(timeIntervalSince1970: fromMs / 1000)
    let to = Date(timeIntervalSince1970: toMs / 1000)

    let group = DispatchGroup()
    var payload: [[String: Any]] = []

    group.enter()
    fetchSleep(from: from, to: to) { events in
      payload.append(contentsOf: events)
      group.leave()
    }

    group.enter()
    fetchWorkouts(from: from, to: to) { events in
      payload.append(contentsOf: events)
      group.leave()
    }

    group.notify(queue: .main) {
      result(payload)
    }
  }

  private func fetchSleep(from: Date, to: Date, completion: @escaping ([[String: Any]]) -> Void) {
    guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
      completion([])
      return
    }

    let predicate = HKQuery.predicateForSamples(
      withStart: from,
      end: to,
      options: [.strictStartDate]
    )

    let query = HKSampleQuery(
      sampleType: sleepType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, _ in
      let categorySamples = (samples as? [HKCategorySample]) ?? []
      let events = categorySamples.compactMap { sample -> [String: Any]? in
        if sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue {
          return nil
        }

        return [
          "id": "sleep-\(sample.uuid.uuidString)",
          "domain": "sleep",
          "startAtMs": Int(sample.startDate.timeIntervalSince1970 * 1000),
          "endAtMs": Int(sample.endDate.timeIntervalSince1970 * 1000),
          "source": "healthkit",
        ]
      }
      completion(events)
    }

    healthStore.execute(query)
  }

  private func fetchWorkouts(
    from: Date,
    to: Date,
    completion: @escaping ([[String: Any]]) -> Void
  ) {
    let workoutType = HKObjectType.workoutType()
    let predicate = HKQuery.predicateForSamples(
      withStart: from,
      end: to,
      options: [.strictStartDate]
    )

    let query = HKSampleQuery(
      sampleType: workoutType,
      predicate: predicate,
      limit: HKObjectQueryNoLimit,
      sortDescriptors: nil
    ) { _, samples, _ in
      let workouts = (samples as? [HKWorkout]) ?? []
      let events = workouts.map { workout in
        [
          "id": "workout-\(workout.uuid.uuidString)",
          "domain": "exercise",
          "startAtMs": Int(workout.startDate.timeIntervalSince1970 * 1000),
          "endAtMs": Int(workout.endDate.timeIntervalSince1970 * 1000),
          "source": "healthkit",
        ]
      }
      completion(events)
    }

    healthStore.execute(query)
  }
}
