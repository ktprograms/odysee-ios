//
//  FileTableViewCell.swift
//  Odysee
//
//  Created by Akinwale Ariwodola on 08/11/2020.
//

import UIKit

class ClaimTableViewCell: UITableViewCell {
    static let nib = UINib(nibName: "ClaimTableViewCell", bundle: nil)
    static let spacemanImage = UIImage(named: "spaceman")
    static let thumbImageSpec = ImageSpec(size: CGSize(width: 390, height: 220))
    static let channelImageSpec = ImageSpec(size: CGSize(width: 100, height: 0))

    @IBOutlet var channelImageView: UIImageView!
    @IBOutlet var thumbnailImageView: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var publisherLabel: UILabel!
    @IBOutlet var publishTimeLabel: UILabel!
    @IBOutlet var durationView: UIView!
    @IBOutlet var durationLabel: UILabel!

    var currentClaim: Claim?
    var reposterChannelClaim: Claim?

    var reposterOverlay: UIStackView!
    var reposterLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        let publisherTapGesture = UITapGestureRecognizer(target: self, action: #selector(publisherTapped(_:)))
        publisherLabel.addGestureRecognizer(publisherTapGesture)
        channelImageView.rounded()
        channelImageView.backgroundColor = Helper.lightPrimaryColor
        thumbnailImageView.backgroundColor = Helper.lightPrimaryColor
        createRepostOverlay()
    }

    static func imagePrefetchURLs(claim: Claim) -> [URL] {
        if claim.claimId == "placeholder" || claim.claimId == "new" {
            return []
        }

        var actualClaim: Claim = claim
        if claim.valueType == ClaimType.repost && claim.repostedClaim != nil {
            actualClaim = claim.repostedClaim!
        }

        var result = [URL]()
        if let thumbnailUrl = actualClaim.value?.thumbnail?.url.flatMap(URL.init) {
            let isChannel = actualClaim.name?.starts(with: "@") ?? false
            let spec = isChannel ? Self.channelImageSpec : Self.thumbImageSpec
            result.append(thumbnailUrl.makeImageURL(spec: spec))
        }
        return result
    }

    func setClaim(claim: Claim) {
        var actualClaim: Claim = claim
        if claim.valueType == ClaimType.repost && claim.repostedClaim != nil {
            reposterOverlay.isHidden = false
            reposterChannelClaim = claim.signingChannel
            reposterLabel.text = reposterChannelClaim?.name ?? claim.shortUrl
            actualClaim = claim.repostedClaim!
        } else {
            reposterOverlay.isHidden = true
        }

        if currentClaim != nil && actualClaim.claimId != currentClaim!.claimId {
            // reset the thumbnail image (to prevent the user from seeing image load changes when scrolling due to cell reuse)
            thumbnailImageView.pin_cancelImageDownload()
            thumbnailImageView.image = nil
            thumbnailImageView.backgroundColor = nil
            channelImageView.pin_cancelImageDownload()
            channelImageView.image = nil
            channelImageView.backgroundColor = nil
        }

        backgroundColor = actualClaim.featured ? UIColor.black : nil

        thumbnailImageView.backgroundColor = actualClaim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        titleLabel.backgroundColor = actualClaim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        publisherLabel.backgroundColor = actualClaim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        publishTimeLabel.backgroundColor = actualClaim.claimId == "placeholder" ? UIColor.systemGray5 : UIColor.clear
        durationView.isHidden = actualClaim.claimId == "placeholder" || actualClaim.claimId == "new"

        if actualClaim.claimId == "placeholder" {
            titleLabel.text = nil
            publisherLabel.text = nil
            publishTimeLabel.text = nil
            return
        }

        if actualClaim.claimId == "new" {
            titleLabel.text = String.localized("New Upload")
            publisherLabel.text = nil
            publishTimeLabel.text = nil
            thumbnailImageView.image = Self.spacemanImage
            return
        }

        currentClaim = actualClaim

        let isChannel = actualClaim.name!.starts(with: "@")
        channelImageView.isHidden = !isChannel
        thumbnailImageView.isHidden = isChannel

        titleLabel.textColor = actualClaim.featured ? UIColor.white : nil
        titleLabel.text = isChannel ? actualClaim.name : actualClaim.value?.title
        publisherLabel.text = isChannel ? actualClaim.name : actualClaim.signingChannel?.name
        if actualClaim.value?.source == nil, !isChannel {
            publisherLabel.text = "LIVE"
        }

        // load thumbnail url
        if let thumbnailUrl = actualClaim.value?.thumbnail?.url.flatMap(URL.init) {
            if isChannel {
                channelImageView.load(url: thumbnailUrl.makeImageURL(spec: Self.channelImageSpec))
            } else {
                thumbnailImageView.load(url: thumbnailUrl.makeImageURL(spec: Self.thumbImageSpec))
            }
        } else {
            if isChannel {
                channelImageView.image = Self.spacemanImage
                channelImageView.backgroundColor = Helper.lightPrimaryColor
            } else {
                thumbnailImageView.image = Self.spacemanImage
                thumbnailImageView.backgroundColor = Helper.lightPrimaryColor
            }
        }

        var releaseTime = Double(actualClaim.value?.releaseTime ?? "0")!
        if releaseTime == 0 {
            releaseTime = Double(actualClaim.timestamp ?? 0)
        }

        publishTimeLabel.textColor = actualClaim.featured ? UIColor.white : nil
        if releaseTime > 0 {
            let date = Date(timeIntervalSince1970: releaseTime) // TODO: Timezone check / conversion?
            publishTimeLabel.text = Helper.fullRelativeDateFormatter.localizedString(for: date, relativeTo: Date())
        } else {
            publishTimeLabel.text = String.localized("Pending")
        }

        var duration: Int64 = 0
        if actualClaim.value?.video != nil || actualClaim.value?.audio != nil {
            let streamInfo = actualClaim.value?.video ?? actualClaim.value?.audio
            duration = streamInfo?.duration ?? 0
        }

        durationView.isHidden = duration <= 0
        if duration > 0 {
            if duration < 60 {
                durationLabel.text = String(format: "0:%02d", duration)
            } else {
                durationLabel.text = Helper.durationFormatter.string(from: TimeInterval(duration))
            }
        }
    }

    private func createRepostOverlay() {
        reposterOverlay = UIStackView()
        reposterOverlay.backgroundColor = Helper.primaryColor.withAlphaComponent(0.8)
        reposterOverlay.bounds = CGRect(x: 0, y: 0, width: 116, height: 30)
        reposterOverlay.layer.anchorPoint = CGPoint(x: 0.5, y: 0)
        reposterOverlay.layer.position = CGPoint(x: 20, y: 20)
        reposterOverlay.transform = CGAffineTransform(rotationAngle: -45.0 / 180.0 * .pi)
        reposterOverlay.axis = .vertical
        reposterOverlay.alignment = .center
        contentView.addSubview(reposterOverlay)
        reposterOverlay.isHidden = true

        let imageView = UIImageView(image: UIImage(systemName: "arrow.triangle.2.circlepath")!)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.tintColor = .white
        reposterOverlay.addArrangedSubview(imageView)
        addConstraints([
            imageView.widthAnchor.constraint(equalToConstant: 18),
            imageView.heightAnchor.constraint(equalToConstant: 14)
        ])

        reposterLabel = UILabel()
        reposterLabel.translatesAutoresizingMaskIntoConstraints = false
        reposterLabel.textColor = .white
        reposterLabel.textAlignment = .center
        reposterLabel.font = .systemFont(ofSize: 12)
        reposterOverlay.addArrangedSubview(reposterLabel)
        addConstraints([
            reposterLabel.widthAnchor.constraint(equalTo: reposterOverlay.widthAnchor, constant: -25)
        ])

        let reposterTapGesture = UITapGestureRecognizer(target: self, action: #selector(reposterTapped(_:)))
        reposterOverlay.addGestureRecognizer(reposterTapGesture)
    }

    @objc func publisherTapped(_ sender: Any) {
        if currentClaim!.signingChannel != nil {
            let channelClaim = currentClaim!.signingChannel!
            let appDelegate = UIApplication.shared.delegate as! AppDelegate

            let currentVc = UIApplication.currentViewController()
            if let channelVc = currentVc as? ChannelViewController {
                if channelVc.channelClaim?.claimId == channelClaim.claimId {
                    // if we already have the channel page open, don't do anything
                    return
                }
            }

            let vc = appDelegate.mainController.storyboard?
                .instantiateViewController(identifier: "channel_view_vc") as! ChannelViewController
            vc.channelClaim = channelClaim
            appDelegate.mainNavigationController?.pushViewController(vc, animated: true)
        }
    }

    @objc func reposterTapped(_ sender: Any) {
        if let channelClaim = reposterChannelClaim {
            let appDelegate = UIApplication.shared.delegate as! AppDelegate

            if let currentVc = UIApplication.currentViewController() as? ChannelViewController {
                if currentVc.channelClaim?.claimId == channelClaim.claimId {
                    // if we already have the channel page open, don't do anything
                    return
                }
            }

            let vc = appDelegate.mainController.storyboard?
                .instantiateViewController(withIdentifier: "channel_view_vc") as! ChannelViewController
            vc.channelClaim = channelClaim
            appDelegate.mainNavigationController?.pushViewController(vc, animated: true)
        }
    }
}
