//
//  main.swift
//
//  Created by jonnyyu on 2023/3/23.
//

import Foundation
import Cocoa
import AltSign
import ArgumentParserKit

extension ALTDevice {}

enum ArgValidateError: Error {
    case invalidLength
    case notConnectedDevice
    case IpaPathNotFound
    case notOutputOrInstall
    case appleIDOrPassswordUndefined
    case certificateOrProfileUndefined
    case certificateNotFound
    case profileNotFound
}

class Application: NSObject {

    private let pluginManager = PluginManager()
    

    func launch() async throws
    {

        let arguments = Array(CommandLine.arguments.dropFirst())
        let parser = ArgumentParser(usage: "<options>", overview: "A description")
        let ipaOption = parser.add(option: "--ipa", shortName: "-ipa", kind: String.self, usage: "ipa path")
        let typeOption = parser.add(option: "--type", shortName: "-t", kind: String.self, usage: "apple sign type: appleId or certificate")

        let usernameOption = parser.add(option: "--appleId", shortName: "-a", kind: String.self, usage: "apple ID")
        let passwordOption = parser.add(option: "--password", shortName: "-p", kind: String.self, usage: "apple password")
        let deviceIdOption = parser.add(option: "--deviceId", shortName: "-di", kind: String.self, usage: "device udid。 required when")
        let deviceNameOption = parser.add(option: "--deviceName", shortName: "-dn", kind: String.self, usage: "device name")
        let bundleIdOption = parser.add(option: "--bundleId", shortName: "-bi", kind: String.self, usage: "the bundleId, same|auto|xx.xx.xx(specified bundleId)")

        let certificatePathOption = parser.add(option: "--certificatePath", shortName: "-cpa", kind: String.self, usage: "certificate path")
        let certificatePasswordOption = parser.add(option: "--certificatePassword", shortName: "-cpw", kind: String.self, usage: "certificate password")
        let profilePathOption = parser.add(option: "--profilePath", shortName: "-pf", kind: String.self, usage: "profile path")

        let outputDirOption = parser.add(option: "--output", shortName: "-o", kind: String.self, usage: "output dir")
        let installOption = parser.add(option: "--install", shortName: "-i", kind: Bool.self, usage: "install instantly to device")
        let parsedArguments = try parser.parse(arguments)

        let signType = parsedArguments.get(typeOption) ?? "appleId"
        var ipaPath = parsedArguments.get(ipaOption)

        var username = parsedArguments.get(usernameOption)
        var password = parsedArguments.get(passwordOption)
        let deviceId = parsedArguments.get(deviceIdOption)
        var deviceName = parsedArguments.get(deviceNameOption)

        let certificatePath = parsedArguments.get(certificatePathOption)
        let certificatePassword = parsedArguments.get(certificatePasswordOption)
        let profilePath = parsedArguments.get(profilePathOption)

        let install = parsedArguments.get(installOption) ?? false
        let outputDir = parsedArguments.get(outputDirOption)
        let bundleId = parsedArguments.get(bundleIdOption) ?? "same"


        if ipaPath == nil {
           printStdErr("the ipa path not found")
           throw ArgValidateError.notConnectedDevice
       }
        ipaPath = ipaPath!.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)!;
        let fileURL =  URL(fileURLWithPath: ipaPath!)
        
        // output或install至少一种
        if outputDir == nil && !install {
            printStdErr("not output Dir or install instantly")
            throw ArgValidateError.notOutputOrInstall
        }

       if signType == "appleId" {
           if username == nil || password == nil {
               let executableURL = URL(fileURLWithPath: CommandLine.arguments[0])
               let inputCommand = executableURL.deletingLastPathComponent().appendingPathComponent("./appleAccount.sh").path
               let inputOutput = executeCommand(inputCommand)
               if let input = inputOutput {
                   let inputLines = input.split(separator: "\n")
                   if inputLines.count < 2  {
                       printStdErr("appleID or password is undefined")
                       throw ArgValidateError.appleIDOrPassswordUndefined
                   }
                   username = String(inputLines[0])
                   password = String(inputLines[1])
               } else {
                   printStdErr("appleID or password is undefined")
                   throw ArgValidateError.appleIDOrPassswordUndefined
               }
           }
       } else {
            if certificatePath == nil || profilePath == nil {
                printStdErr("certificate or profile is undefined")
                throw ArgValidateError.certificateOrProfileUndefined
            }
           guard FileManager.default.fileExists(atPath: certificatePath!) else {
                 printStdErr("certificate not found")
                throw ArgValidateError.certificateNotFound
            }
           guard FileManager.default.fileExists(atPath: profilePath!) else {
                 printStdErr("profile not found")
                throw ArgValidateError.profileNotFound
            }
       }

        // 采用appleId方式，或者开启install需要有deviceId
        var device: ALTDevice? = nil
        if signType == "appleId" || install {
            if deviceId == nil {
                ALTDeviceManager.shared.start()
                if ALTDeviceManager.shared.availableDevices.count == 0 {
                    printStdErr("not connected device")
                    throw ArgValidateError.notConnectedDevice
                }
                device = ALTDeviceManager.shared.availableDevices[0]
            } else {
                deviceName = deviceName ?? "your iphone"
                device = ALTDevice(name: deviceName!, identifier:deviceId!, type: ALTDeviceType.iphone);
            }
        }

        UserDefaults.standard.registerDefaults()

        try await self.doAction(
            at: fileURL,
            signType: signType,
            username: username,
            password: password,
            certificatePath: certificatePath,
            certificatePassword: certificatePassword,
            profilePath: profilePath,
            to: device,
            outputDir: outputDir,
            install: install,
            bundleId: bundleId
        )
        
    }
}

private extension Application
{

    func doAction(
        at fileURL: URL,
        signType: String,
        username: String?,
        password: String?,
        certificatePath: String?,
        certificatePassword: String?,
        profilePath: String?,
        to device: ALTDevice?,
        outputDir: String?,
        install: Bool,
        bundleId: String?
    ) async throws
    {
       try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) -> Void in

            func finish(_ result: Result<Void, Error>)
            {
                
                switch result
                {
                case .success(let application):
                    continuation.resume(returning: ())
                case .failure(OperationError.cancelled), .failure(ALTAppleAPIError.requiresTwoFactorAuthentication):
                    // Ignore
                    continuation.resume(returning: ())
                    break
                    
                case .failure(let error):
                    continuation.resume(throwing: error)
                }
            }

            func signFinish(_ result: Result<(ALTApplication, Set<String>), Error>)
            {
                 do{
                    let (application, profiles) = try result.get()
                    if outputDir != nil {
                        let resignedIPAURL = try FileManager.default.zipAppBundle(at: application.fileURL);
                        let ipaName = application.fileURL.lastPathComponent.replacingOccurrences(of: ".app", with: ".ipa")
                        let distIPAURL = URL(fileURLWithPath: outputDir!).appendingPathComponent(ipaName)
                        if FileManager.default.fileExists(atPath: distIPAURL.path) {
                            try FileManager.default.removeItem(at: distIPAURL)
                        }
                        try FileManager.default.moveItem(at: resignedIPAURL, to: distIPAURL)
                        print("Export the ipa successfullly")
                    }
                    if install {
                        ALTDeviceManager.shared.installApplication(at: application.fileURL, to: device!, profiles: profiles,  completion: finish(_:))
                    } else {
                        finish(.success(()))
                    }
                }
                catch
                {
                    finish(.failure(error))
                }
            }
        
            if signType == "appleId"
            {
                if !self.pluginManager.isMailPluginInstalled
                {
                    self.pluginManager.installMailPlugin { (result) in
                        DispatchQueue.main.async {
                            switch result
                            {
                            case .failure(let error):
                                printStdErr("Failed to Install Mail Plug-in", error.localizedDescription)
                                finish(.failure(error))
                            case .success:
                                finish(.failure(PluginError.taskError(output: "Mail Plug-in had Installed, Please restart Mail and enable MiniAppPlugin in Mail's Preferences. Mail must be running when signing and installing apps")))
                            }
                        }
                    }
                    return
                }
                ALTDeviceManager.shared.signWithAppleID(at: fileURL, to: device!, appleID: username!, password: password!, bundleId: bundleId, completion: signFinish)
            } else {
                ALTDeviceManager.shared.signWithCertificate(at: fileURL, certificatePath: certificatePath!, certificatePassword: certificatePassword, profilePath: profilePath!, completion: signFinish)
            }
        }
   }
}

do {
    let app = Application()
    try await app.launch()
} catch {
    printStdErr("error:", error)
    exit(1)
}
